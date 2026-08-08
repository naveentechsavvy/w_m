import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  requestApproved,
  requestRejected,
  meetupReminder,
  announcement,
  newMessage,
  generic,
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.generic,
    );
  }
}

/// Backed by Firestore collection `notifications`.
/// Join requests are NOT stored here — they live in `join_requests`
/// and are merged into the feed at the controller level.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // e.g. meetupId, chatId
  final String userId; // recipient

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.userId,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'userId': userId,
      'relatedId': relatedId,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: NotificationTypeX.fromString(map['type'] ?? ''),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      userId: map['userId'] ?? '',
      relatedId: map['relatedId'],
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId,
      relatedId: relatedId,
    );
  }
}