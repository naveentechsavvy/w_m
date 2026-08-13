import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification_model.dart';

class NotificationDataSource {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('notifications');

  /// Creates a new notification doc for [userId] (the recipient).
  /// Used by join-request approve/reject right now; any future
  /// notification-producing action (meetup reminder, announcement, new
  /// message) should call this same method rather than writing to the
  /// `notifications` collection directly, to keep the doc shape
  /// consistent everywhere.
  Future<void> create({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    final notification = AppNotification(
      id: '',
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      userId: userId,
      relatedId: relatedId,
    );
    await _collection.add(notification.toMap());
  }

  Future<List<AppNotification>> getForUser(String uid) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _collection.doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
