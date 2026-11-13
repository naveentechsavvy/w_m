import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/models/app_notification_model.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Chat controller for all three chat types. Opened via:
///
/// Group chat:
///   Get.toNamed(AppRoutes.chat, arguments: {
///     'chatType': 'group',
///     'meetupId': id,
///     'meetupTitle': title,
///     'organizerId': meetup.createdBy, // required for moderation/mute
///   });
///
/// Private / Organizer chat:
///   Get.toNamed(AppRoutes.chat, arguments: {
///     'chatType': 'private', // or 'organizer'
///     'meetupId': id,
///     'meetupTitle': title,
///     'otherUserId': otherUid,
///     'otherUserName': otherName,
///   });
///
/// A fresh ChatController is created per chat via binding (tag = roomId)
/// rather than reused as a singleton — otherwise switching between a
/// group chat and a private chat in the same session would collide on a
/// single untagged Get.find<ChatController>() instance. Register it as:
///   Get.lazyPut<ChatController>(() => ChatController(), tag: roomId);
/// and resolve the same way in ChatScreen.
class ChatController extends GetxController {
  final ChatRepository repository = ChatRepository();
  final NotificationRepository notificationRepository = NotificationRepository();

  /// Own messages can be edited/deleted only within this window of
  /// sending — matches the common WhatsApp-style edit-window pattern.
  static const Duration _editWindow = Duration(minutes: 15);

  static String resolveRoomId(Map args, String currentUid) {
    final chatType = ChatType.fromValue(args['chatType'] as String?);
    final meetupId = args['meetupId'] ?? '';
    if (chatType == ChatType.group) return meetupId;
    final otherUserId = args['otherUserId'] as String? ?? '';
    return ChatRepository.buildDirectRoomId(
      meetupId: meetupId,
      uidA: currentUid,
      uidB: otherUserId,
    );
  }

  late final ChatType chatType;
  late final String meetupId;
  late final String meetupTitle;
  late final String roomId;

  /// Only set for private/organizer chats. Null for group chat.
  String? otherUserId;
  String? otherUserName;

  /// Meetup creator's uid. Drives [isOrganizer] — the only thing that
  /// unlocks moderation (removing others' messages, muting members).
  /// Null if the caller didn't pass it, in which case isOrganizer is
  /// always false rather than throwing, so existing callers that don't
  /// pass it yet just get no moderation UI instead of crashing.
  String? organizerId;

  final RxList<Message> messages = <Message>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isReady = false.obs;
  final TextEditingController textController = TextEditingController();

  final Rxn<Message> editingMessage = Rxn<Message>();

  /// If set and in the future, the current user is muted in this room
  /// until this time — send() blocks and the input bar shows why.
  /// Streamed live so an organizer's mute/unmute takes effect without
  /// the muted user needing to reopen the screen.
  final Rxn<DateTime> mutedUntil = Rxn<DateTime>();

  StreamSubscription<List<Message>>? _sub;
  StreamSubscription<DateTime?>? _muteSub;
  String _senderName = 'You';

  bool _hasRetriedSubscription = false;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// True only for the meetup's creator. Group chat only — private and
  /// organizer 1:1 threads have no "members" to moderate.
  bool get isOrganizer =>
      chatType == ChatType.group &&
      organizerId != null &&
      organizerId!.isNotEmpty &&
      currentUid == organizerId;

  /// True if the current user is muted in this room right now.
  bool get isMuted =>
      mutedUntil.value != null && mutedUntil.value!.isAfter(DateTime.now());

  String get displayTitle {
    switch (chatType) {
      case ChatType.group:
        return meetupTitle.isNotEmpty ? meetupTitle : 'Group Chat';
      case ChatType.private:
      case ChatType.organizer:
        return otherUserName?.isNotEmpty == true
            ? otherUserName!
            : (chatType == ChatType.organizer ? 'Organizer' : 'Chat');
    }
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    final map = args is Map ? args : <String, dynamic>{};

    chatType = ChatType.fromValue(map['chatType'] as String?);
    meetupId = map['meetupId'] ?? '';
    meetupTitle = map['meetupTitle'] ?? '';
    otherUserId = map['otherUserId'] as String?;
    otherUserName = map['otherUserName'] as String?;
    organizerId = map['organizerId'] as String?;

    if ((chatType == ChatType.private || chatType == ChatType.organizer) &&
        (otherUserId == null || otherUserId!.isEmpty)) {
      throw ArgumentError(
        'ChatController: otherUserId is required for chatType '
        '${chatType.value}',
      );
    }

    roomId = chatType == ChatType.group
        ? meetupId
        : ChatRepository.buildDirectRoomId(
            meetupId: meetupId,
            uidA: currentUid ?? '',
            uidB: otherUserId!,
          );

    _init();
  }

  Future<void> _init() async {
    await _loadSenderName();

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.authStateChanges().firstWhere(
            (user) => user != null,
          );
    }

    _subscribeToMessages();
    _subscribeToMuteStatus();
    isReady.value = true;
  }

  Future<void> _loadSenderName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('full_name') ?? '';
    if (name.trim().isNotEmpty) {
      _senderName = name.trim();
    }
  }

  void _subscribeToMessages() {
    _sub = repository
        .streamMessages(
      roomId: roomId,
      chatType: chatType,
      currentUid: currentUid ?? '',
    )
        .listen(
      (list) {
        messages.assignAll(list);
      },
      onError: (error) {
        debugPrint('Chat stream error: $error');

        if (!_hasRetriedSubscription) {
          _hasRetriedSubscription = true;
          _sub?.cancel();
          _subscribeToMessages();
          return;
        }

        Get.snackbar(
          'Chat error',
          'Could not load messages. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  /// Only watches the CURRENT user's own mute status — every user only
  /// needs to know "am I muted", not the mute state of everyone else in
  /// the room.
  void _subscribeToMuteStatus() {
    final uid = currentUid;
    if (uid == null) return;

    _muteSub = repository
        .streamMuteStatus(roomId: roomId, userId: uid)
        .listen((until) {
      mutedUntil.value = until;
    }, onError: (e) {
      debugPrint('Mute status stream error: $e');
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _muteSub?.cancel();
    textController.dispose();
    super.onClose();
  }

  bool canEditOrDelete(Message message) {
    if (message.senderId != currentUid) return false;
    if (message.isDeleted) return false;
    return DateTime.now().difference(message.sentAt) <= _editWindow;
  }

  void startEdit(Message message) {
    if (!canEditOrDelete(message)) return;
    editingMessage.value = message;
    textController.text = message.text;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  void cancelEdit() {
    editingMessage.value = null;
    textController.clear();
  }

  Future<void> send() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final uid = currentUid;
    if (uid == null) {
      Get.snackbar(
        'Not signed in',
        'Please sign in again to send messages.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isMuted) {
      Get.snackbar(
        'You are muted',
        'You can send messages again after ${_formatMuteUntil(mutedUntil.value!)}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final editing = editingMessage.value;
    if (editing != null) {
      await _saveEdit(editing, text);
      return;
    }

    isSending.value = true;
    try {
      await repository.sendMessage(
        roomId: roomId,
        meetupId: meetupId,
        chatType: chatType,
        senderName: _senderName,
        text: text,
        otherUserId: otherUserId,
      );
      textController.clear();

      if ((chatType == ChatType.private || chatType == ChatType.organizer) &&
          otherUserId != null &&
          otherUserId!.isNotEmpty) {
        notificationRepository
            .create(
          userId: otherUserId!,
          type: NotificationType.newMessage,
          title: _senderName,
          body: text.length > 80 ? '${text.substring(0, 80)}…' : text,
          relatedId: roomId,
        )
            .catchError((e) {
          debugPrint('Failed to create message notification: $e');
        });
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      Get.snackbar(
        'Message not sent',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _saveEdit(Message original, String newText) async {
    if (!canEditOrDelete(original)) {
      Get.snackbar(
        'Can\'t edit this message',
        'The edit window for this message has passed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      cancelEdit();
      return;
    }

    isSending.value = true;
    try {
      await repository.editMessage(messageId: original.id, newText: newText);
      cancelEdit();
    } catch (e) {
      debugPrint('Edit message error: $e');
      Get.snackbar(
        'Edit not saved',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteMessage(Message message) async {
    if (!canEditOrDelete(message)) {
      Get.snackbar(
        'Can\'t delete this message',
        'The delete window for this message has passed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (editingMessage.value?.id == message.id) {
      cancelEdit();
    }

    try {
      await repository.deleteMessage(message.id);
    } catch (e) {
      debugPrint('Delete message error: $e');
      Get.snackbar(
        'Delete failed',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Organizer-only: removes ANY message in the room, regardless of
  /// sender or how long ago it was sent — bypasses canEditOrDelete()
  /// entirely, since that check is specifically for a user managing
  /// their own message.
  Future<void> moderateDeleteMessage(Message message) async {
    if (!isOrganizer) return;
    if (message.isDeleted) return;

    try {
      await repository.deleteMessage(message.id);
    } catch (e) {
      debugPrint('Moderate delete error: $e');
      Get.snackbar(
        'Couldn\'t remove message',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Organizer-only: stops [userId] from sending in this room until
  /// now + [duration].
  Future<void> muteMember(String userId, Duration duration) async {
    if (!isOrganizer) return;

    final uid = currentUid;
    if (uid == null) return;

    try {
      await repository.muteUser(
        roomId: roomId,
        userId: userId,
        mutedUntil: DateTime.now().add(duration),
        mutedBy: uid,
      );
      Get.snackbar(
        'Member muted',
        'They won\'t be able to send messages for a while.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Mute member error: $e');
      Get.snackbar(
        'Couldn\'t mute',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Organizer-only: lifts a mute early.
  Future<void> unmuteMember(String userId) async {
    if (!isOrganizer) return;

    try {
      await repository.unmuteUser(roomId: roomId, userId: userId);
    } catch (e) {
      debugPrint('Unmute member error: $e');
      Get.snackbar(
        'Couldn\'t unmute',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatMuteUntil(DateTime dt) {
    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }
}