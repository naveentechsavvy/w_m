import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemLine {
  final String itemId;
  final String name;
  final double price;
  final int quantity;

  OrderItemLine({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemLine.fromMap(Map<String, dynamic> map) {
    return OrderItemLine(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0) as int,
    );
  }
}

/// The fixed set of statuses an order can move through. Kept as a plain
/// ordered list (not an enum) so the tracking UI can index into it directly.
const List<String> kOrderStatusSteps = [
  'placed',
  'preparing',
  'out_for_delivery',
  'delivered',
];

/// Some older/legacy documents (and the current checkout flow) write
/// 'created' where 'placed' was intended. This map normalizes those
/// aliases so status lookups behave consistently everywhere.
const Map<String, String> _statusAliases = {
  'created': 'placed',
};

String normalizeOrderStatus(String rawStatus) {
  return _statusAliases[rawStatus] ?? rawStatus;
}

class FoodOrder {
  final String id;
  final String userId;
  final List<OrderItemLine> items;
  final double total;
  final String status;
  final Map<String, dynamic>? deliveryAddress;
  final DateTime? createdAt;

  /// Coupon info (only on orders placed with a coupon).
  /// [total] is always the amount paid, after the discount.
  final double discount;
  final String? couponCode;

  FoodOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    this.deliveryAddress,
    this.createdAt,
    this.discount = 0,
    this.couponCode,
  });

  factory FoodOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = (data['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemLine.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return FoodOrder(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: rawItems,
      total: (data['total'] ?? 0).toDouble(),
      status: normalizeOrderStatus(data['status'] ?? 'placed'),
      deliveryAddress: data['deliveryAddress'] != null
          ? Map<String, dynamic>.from(data['deliveryAddress'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      discount: (data['discount'] ?? 0).toDouble(),
      couponCode: data['couponCode'] as String?,
    );
  }

  int get statusIndex {
    final idx = kOrderStatusSteps.indexOf(status);
    return idx == -1 ? 0 : idx;
  }
}