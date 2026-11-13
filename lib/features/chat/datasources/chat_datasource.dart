import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

class ChatDataSource {
  final _messages = FirebaseFirestore.instance.collection('messages');

  /// One doc per (room, user) tracking a temporary mute the organizer
  /// placed on that user in that room. Doc id is deterministic so
  /// muting the same person twice just overwrites the old mute instead
  /// of creating duplicate active mutes.
  final _mutes = FirebaseFirestore.instance.collection('chat_mutes');

  static String buildDirectRoomId({
    required String meetupId,
    required String uidA,
    required String uidB,
  }) {
    final sorted = [uidA, uidB]..sort();
    return '${meetupId}_${sorted[0]}_${sorted[1]}';
  }

  static String _muteDocId(String roomId, String userId) =>
      '${roomId}_$userId';

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

  /// Soft-deletes a message. Used both for a user deleting their own
  /// message AND for an organizer removing someone else's — ownership
  /// is decided by the caller (ChatController), not here, same as the
  /// existing PERMISSION NOTE above already established for edit/delete.
  Future<void> deleteMessage(String messageId) async {
    await _messages.doc(messageId).update({
      'isDeleted': true,
      'text': '',
    });
  }

  /// Mutes [userId] in [roomId] until [mutedUntil]. Overwrites any
  /// existing mute for that user in that room (set, not update — the
  /// doc may not exist yet).
  Future<void> muteUser({
    required String roomId,
    required String userId,
    required DateTime mutedUntil,
    required String mutedBy,
  }) async {
    await _mutes.doc(_muteDocId(roomId, userId)).set({
      'roomId': roomId,
      'userId': userId,
      'mutedUntil': Timestamp.fromDate(mutedUntil),
      'mutedBy': mutedBy,
    });
  }

  /// Lifts a mute early. Deletes the doc rather than clearing
  /// mutedUntil so streamMuteStatus() naturally returns null again.
  Future<void> unmuteUser({
    required String roomId,
    required String userId,
  }) async {
    await _mutes.doc(_muteDocId(roomId, userId)).delete();
  }

  /// Live mute expiry for [userId] in [roomId], or null if not muted.
  /// Streamed (not fetched once) so if the organizer mutes/unmutes
  /// while the muted user has the chat open, their input bar
  /// updates immediately without needing to reopen the screen.
  Stream<DateTime?> streamMuteStatus({
    required String roomId,
    required String userId,
  }) {
    return _mutes.doc(_muteDocId(roomId, userId)).snapshots().map((doc) {
      if (!doc.exists) return null;
      final ts = doc.data()?['mutedUntil'] as Timestamp?;
      return ts?.toDate();
    });
  }
}