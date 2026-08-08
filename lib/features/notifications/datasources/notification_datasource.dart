import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification_model.dart';

class NotificationDataSource {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('notifications');

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