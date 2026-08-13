import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Chat controller for all three chat types. Opened via:
///
/// Group chat:
///   Get.toNamed(AppRoutes.chat, arguments: {
///     'chatType': 'group',
///     'meetupId': id,
///     'meetupTitle': title,
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

  /// Own messages can be edited/deleted only within this window of
  /// sending — matches the common WhatsApp-style edit-window pattern.
  /// Same window applies to both actions for simplicity; split them into
  /// separate durations later if edit and delete ever need different
  /// limits.
  static const Duration _editWindow = Duration(minutes: 15);

  /// Computes the same roomId the controller will use internally, from
  /// raw route arguments + the current uid. Exposed as a static method so
  /// chat_binding.dart can compute an identical tag BEFORE the controller
  /// is constructed — e.g.:
  ///
  ///   final roomId = ChatController.resolveRoomId(Get.arguments, uid);
  ///   Get.lazyPut<ChatController>(() => ChatController(), tag: roomId);
  ///
  /// and ChatScreen resolves with the same tag:
  ///
  ///   Get.find<ChatController>(tag: ChatController.resolveRoomId(...))
  ///
  /// This keeps group/private/organizer chats from colliding on a single
  /// untagged controller instance if more than one is ever alive at once.
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

  final RxList<Message> messages = <Message>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isReady = false.obs;
  final TextEditingController textController = TextEditingController();

  /// Null when composing a new message. Set when the user long-presses
  /// one of their own messages and taps Edit — send() branches on this
  /// to call editMessage() instead of sendMessage(), and the input bar
  /// shows an "Editing message" strip above the text field while set.
  final Rxn<Message> editingMessage = Rxn<Message>();

  StreamSubscription<List<Message>>? _sub;
  String _senderName = 'You';

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Title shown in the app bar: meetup title for group chat, the other
  /// person's name for private/organizer chat.
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

    if ((chatType == ChatType.private || chatType == ChatType.organizer) &&
        (otherUserId == null || otherUserId!.isEmpty)) {
      // Fail loudly during development rather than silently loading the
      // wrong room — a missing otherUserId here means a caller forgot to
      // pass route arguments correctly.
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
    _subscribeToMessages();
    isReady.value = true;
  }

  // Profile data currently lives in SharedPreferences (see
  // ProfileViewScreen), not a Firestore users doc — matching that here.
  // Awaited before subscribing so the first message a user sends can
  // never go out with the placeholder name "You" — the previous
  // fire-and-forget version had a race where a fast sender could hit
  // send() before this resolved, permanently writing the wrong name.
  Future<void> _loadSenderName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('full_name') ?? '';
    if (name.trim().isNotEmpty) {
      _senderName = name.trim();
    }
  }

  void _subscribeToMessages() {
    _sub = repository.streamMessages(roomId).listen(
      (list) {
        messages.assignAll(list);
      },
      onError: (error) {
        // Without this handler, a Firestore error (e.g. a missing
        // composite index on roomId + sentAt) fails silently and the
        // UI is stuck showing "No messages yet" with no indication why.
        debugPrint('Chat stream error: $error');
        Get.snackbar(
          'Chat error',
          'Could not load messages. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    textController.dispose();
    super.onClose();
  }

  /// True if [message] belongs to the current user, hasn't already been
  /// deleted, and is still inside the edit/delete window. Drives both
  /// whether the long-press menu offers Edit/Delete and whether the
  /// controller methods below will actually perform the write.
  bool canEditOrDelete(Message message) {
    if (message.senderId != currentUid) return false;
    if (message.isDeleted) return false;
    return DateTime.now().difference(message.sentAt) <= _editWindow;
  }

  /// Enters edit mode for [message]: preloads its text into the input
  /// field and stores it so send() knows to update instead of create.
  void startEdit(Message message) {
    if (!canEditOrDelete(message)) return;
    editingMessage.value = message;
    textController.text = message.text;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
  }

  /// Exits edit mode without saving changes.
  void cancelEdit() {
    editingMessage.value = null;
    textController.clear();
  }

  /// Sends a new message, or — if editingMessage is set — saves an edit
  /// to that message instead. Kept as a single entry point (rather than
  /// two separate button handlers) so the input bar's send button always
  /// does "the right thing" regardless of mode.
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
      );
      textController.clear();
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

    // If the message being deleted is the one currently being edited,
    // exit edit mode first so the input bar doesn't stay pointed at a
    // message that's about to disappear.
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
}