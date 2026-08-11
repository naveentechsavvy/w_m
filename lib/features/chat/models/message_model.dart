import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of chat a message belongs to.
///
/// - [group]: the shared meetup group chat (roomId == meetupId)
/// - [private]: a 1:1 thread between two participants of the same meetup
/// - [organizer]: a 1:1 thread between a participant and the meetup organizer
///
/// [organizer] is stored distinctly from [private] (even though both are
/// 1:1 threads) so we can filter/moderate organizer conversations
/// separately later without touching the room-id scheme.
enum ChatType {
  group,
  private,
  organizer;

  String get value => name;

  static ChatType fromValue(String? value) {
    return ChatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatType.group,
    );
  }
}

/// Represents a single chat message.
///
/// Backed by the flat Firestore collection `messages`, matching the
/// flat-collection style already used for `join_requests`.
///
/// Messages are queried by [roomId], NOT [meetupId] directly:
/// - Group chat:            roomId == meetupId
/// - Private/Organizer chat: roomId == "<meetupId>_<sortedUidA>_<sortedUidB>"
///
/// [meetupId] is still stored on every message (not just encoded in
/// roomId) so we can query "all chats belonging to meetup X" later,
/// e.g. for moderation or admin tooling, without parsing roomId strings.
class Message {
  final String id;
  final String roomId;
  final String meetupId;
  final ChatType chatType;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.roomId,
    required this.meetupId,
    required this.chatType,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'meetupId': meetupId,
      'chatType': chatType.value,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      // Fallback to meetupId for any pre-migration docs that predate the
      // roomId field (old group-chat messages). See migration note in
      // chat_datasource.dart.
      roomId: map['roomId'] ?? map['meetupId'] ?? '',
      meetupId: map['meetupId'] ?? '',
      chatType: ChatType.fromValue(map['chatType'] as String?),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp).toDate(),
    );
  }

  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
