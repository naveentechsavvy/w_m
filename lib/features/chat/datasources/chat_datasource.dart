import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

/// Raw Firestore access for the `messages` collection.
/// Chat needs live updates (unlike the poll-on-mutation pattern used by
/// join_requests), so this exposes a stream instead of Futures for reads.
///
/// MIGRATION NOTE: existing group-chat messages written before this change
/// won't have a `roomId` field. Message.fromMap() falls back to `meetupId`
/// for those docs, so old group messages still display correctly. No
/// backfill script is required for group chat. There is no pre-existing
/// data to migrate for private/organizer chat since those didn't exist yet.
/// The same applies to isEdited/isDeleted — pre-existing docs default to
/// false via Message.fromMap(), no backfill needed there either.
///
/// FIRESTORE INDEX: this query (roomId ==, orderBy sentAt) needs a
/// composite index on (roomId ASC, sentAt ASC). The old (meetupId ASC,
/// sentAt ASC) index can be deleted once nothing queries by meetupId
/// directly anymore.
///
/// PERMISSION NOTE: edit/delete ownership + time-window checks happen in
/// ChatController.canEditOrDelete() using data already streamed to the
/// client, so this layer doesn't re-fetch-and-check before writing. For
/// production hardening, mirror the same senderId + time-window rule in
/// Firestore security rules so it isn't client-enforced only.
class ChatDataSource {
  final _messages = FirebaseFirestore.instance.collection('messages');

  /// Deterministic room id for a 1:1 thread, independent of who opens
  /// the chat first. Sorting the two uids guarantees uidA/uidB order
  /// doesn't produce two different rooms for the same pair of people.
  static String buildDirectRoomId({
    required String meetupId,
    required String uidA,
    required String uidB,
  }) {
    final sorted = [uidA, uidB]..sort();
    return '${meetupId}_${sorted[0]}_${sorted[1]}';
  }

  Stream<List<Message>> streamMessages(String roomId) {
    return _messages
        .where('roomId', isEqualTo: roomId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromDoc(d)).toList());
  }

  Future<void> sendMessage({
    required String roomId,
    required String meetupId,
    required ChatType chatType,
    required String senderName,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot send a message: no authenticated user.');
    }

    final message = Message(
      id: '',
      roomId: roomId,
      meetupId: meetupId,
      chatType: chatType,
      senderId: uid,
      senderName: senderName,
      text: text.trim(),
      sentAt: DateTime.now(),
    );

    await _messages.add(message.toMap());
  }

  /// Updates the text of an existing message and marks it as edited.
  /// Ownership + time-window checks are the caller's responsibility (see
  /// PERMISSION NOTE above) — this method trusts messageId is editable.
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    await _messages.doc(messageId).update({
      'text': newText.trim(),
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Soft-deletes a message: the doc is kept (so stream ordering never
  /// shifts) but isDeleted flips true and text is cleared. The UI renders
  /// a placeholder instead of text for any message with isDeleted == true.
  Future<void> deleteMessage(String messageId) async {
    await _messages.doc(messageId).update({
      'isDeleted': true,
      'text': '',
    });
  }
}