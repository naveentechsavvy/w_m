import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chat message inside a meetup's group chat.
///
/// Backed by Firestore collection `messages`. Each document stores the
/// [meetupId] it belongs to so we can query with a simple where-clause,
/// matching the flat-collection style already used for `join_requests`.
class Message {
  final String id;
  final String meetupId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  Message({
    required this.id,
    required this.meetupId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetupId': meetupId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      meetupId: map['meetupId'] ?? '',
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
