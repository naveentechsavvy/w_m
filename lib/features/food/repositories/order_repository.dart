import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderRepository {
  final _orders = FirebaseFirestore.instance.collection('orders');

  Stream<FoodOrder> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) => FoodOrder.fromDoc(doc));
  }

  Stream<List<FoodOrder>> streamUserOrders(String uid) {
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FoodOrder.fromDoc(d)).toList());
  }

  /// Debug-only: manually advances an order to the next status in
  /// kOrderStatusSteps. Remove once a real kitchen/delivery flow exists.
  Future<void> advanceStatus(String orderId, String currentStatus) async {
    final idx = kOrderStatusSteps.indexOf(currentStatus);
    if (idx == -1 || idx >= kOrderStatusSteps.length - 1) return;
    await _orders.doc(orderId).update({'status': kOrderStatusSteps[idx + 1]});
  }
}