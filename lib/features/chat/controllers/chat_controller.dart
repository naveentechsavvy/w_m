import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

/// Chat for a single meetup's group. Opened via
/// Get.toNamed(AppRoutes.chat, arguments: {'meetupId': id, 'meetupTitle': title})
class ChatController extends GetxController {
  final ChatRepository repository = ChatRepository();

  late final String meetupId;
  late final String meetupTitle;

  final RxList<Message> messages = <Message>[].obs;
  final RxBool isSending = false.obs;
  final TextEditingController textController = TextEditingController();

  StreamSubscription<List<Message>>? _sub;
  String _senderName = 'You';

  String get currentUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    meetupId = args is Map ? (args['meetupId'] ?? '') : (args ?? '');
    meetupTitle = args is Map ? (args['meetupTitle'] ?? '') : '';

    _loadSenderName();

    _sub = repository.streamMessages(meetupId).listen(
      (list) {
        messages.assignAll(list);
      },
      onError: (error) {
        // Without this handler, a Firestore error (e.g. a missing
        // composite index on meetupId + sentAt) fails silently and the
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

  // Profile data currently lives in SharedPreferences (see
  // ProfileViewScreen), not a Firestore users doc — matching that here.
  Future<void> _loadSenderName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('full_name') ?? '';
    if (name.trim().isNotEmpty) {
      _senderName = name.trim();
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    textController.dispose();
    super.onClose();
  }

  Future<void> send() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    isSending.value = true;
    try {
      await repository.sendMessage(
        meetupId: meetupId,
        senderName: _senderName,
        text: text,
      );
      textController.clear();
    } finally {
      isSending.value = false;
    }
  }
}
