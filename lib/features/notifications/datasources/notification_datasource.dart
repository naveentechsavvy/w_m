import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

    return _parseDocs(snapshot.docs);
  }

  /// Live version of [getForUser]: emits the full list again whenever a
  /// notification for [uid] is added or changed (e.g. a coupon sent from
  /// the website), so the screen updates without being reopened.
  /// Uses the composite index notifications(userId ASC, createdAt DESC).
  Stream<List<AppNotification>> streamForUser(String uid) {
    return _collection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50) // only the latest 50
        .snapshots()
        .map((snapshot) => _parseDocs(snapshot.docs));
  }

  /// Deletes one notification doc. Only the notification — a coupon
  /// notification's coupon in `user_coupons` is never touched.
  Future<void> delete(String id) => _collection.doc(id).delete();

  /// Deletes every notification of [uid] (not just the 50 shown), in
  /// batches of at most 450 deletes. Only the `notifications`
  /// collection is touched.
  Future<void> deleteAllForUser(String uid) async {
    const batchSize = 450;
    while (true) {
      final snapshot = await _collection
          .where('userId', isEqualTo: uid)
          .limit(batchSize)
          .get();
      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < batchSize) return;
    }
  }

  /// Parses each doc on its own and skips (and logs) any doc that still
  /// fails, so one bad document can't hide the rest of the list.
  List<AppNotification> _parseDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = <AppNotification>[];
    for (final doc in docs) {
      try {
        result.add(AppNotification.fromMap(doc.id, doc.data()));
      } catch (e) {
        debugPrint('[Notifications] Skipped bad notification ${doc.id}: $e');
      }
    }
    return result;
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
