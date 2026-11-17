import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  requestApproved,
  requestRejected,
  meetupReminder,
  announcement,
  newMessage,

  /// Sent by the admin website when a customer is given a coupon.
  /// Doc also carries `code` and `couponId`.
  coupon,
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

  /// Coupon notifications only (type == coupon).
  final String? code;
  final String? couponId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.userId,
    this.relatedId,
    this.code,
    this.couponId,
  });

  bool get isCoupon => type == NotificationType.coupon;

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'userId': userId,
      'relatedId': relatedId,
      if (code != null) 'code': code,
      if (couponId != null) 'couponId': couponId,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: NotificationTypeX.fromString(map['type']?.toString() ?? ''),
      title: map['title']?.toString() ?? '',
      // Website coupon notifications save both 'body' and 'message'.
      body: (map['body'] ?? map['message'])?.toString() ?? '',
      createdAt: _parseCreatedAt(map['createdAt']),
      isRead: map['isRead'] == true,
      userId: map['userId']?.toString() ?? '',
      relatedId: map['relatedId']?.toString(),
      code: map['code']?.toString(),
      couponId: map['couponId']?.toString(),
    );
  }

  /// Accepts a Firestore Timestamp (normal case), a DateTime, epoch
  /// millis, or an ISO string. Anything else — including null, which is
  /// what a pending serverTimestamp() reads as — falls back to "now", so
  /// one odd document can never break the whole notifications list.
  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
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
      code: code,
      couponId: couponId,
    );
  }
}