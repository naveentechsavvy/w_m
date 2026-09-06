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
/// QUERY-VS-RULES NOTE: streamMessages() branches into two different
/// query shapes (group vs private/organizer) on purpose. Firestore
/// rejects a list query with permission-denied unless the query's own
/// `where` filters let it statically prove every possible returned
/// document satisfies the security rule — a filter on `roomId` alone
/// isn't enough, since the read rule also checks `chatType`/
/// `participants`, fields the query wasn't filtering on. Adding a
/// matching filter for each case (chatType == 'group', or
/// participants arrayContains uid) is what makes Firestore able to
/// prove it and allow the read.
///
/// FIRESTORE INDEXES: this needs TWO composite indexes now:
///   (roomId ASC, chatType ASC, sentAt ASC)        - for group chat
///   (roomId ASC, participants ARRAY, sentAt ASC)  - for private/organizer
/// Firestore will show a console link to auto-create whichever one is
/// missing the first time each query type runs.
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

  /// [currentUid] is required for private/organizer chat so the query
  /// can filter `participants arrayContains uid` — matching the security
  /// rule so Firestore can prove the read is allowed (see QUERY-VS-RULES
  /// NOTE above). Ignored for group chat.
  Stream<List<Message>> streamMessages({
    required String roomId,
    required ChatType chatType,
    required String currentUid,
  }) {
    Query query = _messages.where('roomId', isEqualTo: roomId);

    if (chatType == ChatType.group) {
      query = query.where('chatType', isEqualTo: ChatType.group.value);
    } else {
      query = query.where('participants', arrayContains: currentUid);
    }

    return query
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromDoc(d)).toList());
  }

  /// [otherUserId] is required for private/organizer messages so the
  /// stored [Message.participants] can be set to exactly the two uids
  /// allowed to read this thread — Firestore security rules check this
  /// field. Left null (and participants omitted) for group chat, where
  /// membership isn't enforced at the message level.
  Future<void> sendMessage({
    required String roomId,
    required String meetupId,
    required ChatType chatType,
    required String senderName,
    required String text,
    String? otherUserId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot send a message: no authenticated user.');
    }

    final isDirect = chatType == ChatType.private || chatType == ChatType.organizer;
    if (isDirect && (otherUserId == null || otherUserId.isEmpty)) {
      throw ArgumentError(
        'ChatDataSource.sendMessage: otherUserId is required for chatType '
        '${chatType.value}',
      );
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
      participants: isDirect ? ([uid, otherUserId!]..sort()) : null,
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