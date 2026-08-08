import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

/// Raw Firestore access for the `messages` collection.
/// Chat needs live updates (unlike the poll-on-mutation pattern used by
/// join_requests), so this exposes a stream instead of Futures for reads.
class ChatDataSource {
  final _messages = FirebaseFirestore.instance.collection('messages');

  Stream<List<Message>> streamMessages(String meetupId) {
    return _messages
        .where('meetupId', isEqualTo: meetupId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromDoc(d)).toList());
  }

  Future<void> sendMessage({
    required String meetupId,
    required String senderName,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final message = Message(
      id: '',
      meetupId: meetupId,
      senderId: uid,
      senderName: senderName,
      text: text.trim(),
      sentAt: DateTime.now(),
    );

    await _messages.add(message.toMap());
  }
}
