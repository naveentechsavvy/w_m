import 'package:cloud_firestore/cloud_firestore.dart';

/// One coupon given to one customer.
///
/// Backed by the `user_coupons` collection, which is written by the
/// admin website. The app only READS these docs; marking a coupon as
/// used is done by the `redeemCouponOnOrderPaid` Cloud Function.
class UserCoupon {
  final String id;
  final String userId;
  final String couponId;
  final String code;
  final String description;

  /// 'percent' or 'flat'
  final String discountType;
  final double discountValue;

  /// Upper limit for percent coupons. Null = no limit.
  final double? maxDiscount;
  final double minOrder;

  /// 'food' | 'meetups' | 'all'
  final String appliesTo;
  final DateTime? validFrom;
  final DateTime? validTo;
  final int usesLeft;

  /// 'assigned' or 'used'
  final String status;
  final DateTime? usedAt;
  final String? orderId;

  UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrder,
    required this.appliesTo,
    required this.validFrom,
    required this.validTo,
    required this.usesLeft,
    required this.status,
    this.usedAt,
    this.orderId,
  });

  factory UserCoupon.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserCoupon(
      id: doc.id,
      userId: data['userId'] ?? '',
      couponId: data['couponId'] ?? '',
      code: (data['code'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      discountType: (data['discountType'] ?? 'flat').toString(),
      discountValue: _toDouble(data['discountValue']) ?? 0,
      maxDiscount: _toDouble(data['maxDiscount']),
      minOrder: _toDouble(data['minOrder']) ?? 0,
      appliesTo: (data['appliesTo'] ?? 'all').toString(),
      validFrom: _toDate(data['validFrom']),
      validTo: _toDate(data['validTo']),
      usesLeft: _toDouble(data['usesLeft'])?.toInt() ?? 0,
      status: (data['status'] ?? 'assigned').toString(),
      usedAt: _toDate(data['usedAt']),
      orderId: data['orderId'] as String?,
    );
  }

  // ------------------------------------------------------------
  // Status helpers
  // ------------------------------------------------------------

  /// Coupons that can be used on food orders. 'meetups' coupons are
  /// hidden for now because meetups are free.
  bool get isForFood => appliesTo == 'food' || appliesTo == 'all';

  bool get isUsed => status == 'used' || usesLeft <= 0;

  bool get isExpired =>
      validTo != null && DateTime.now().isAfter(validTo!);

  bool get isNotStartedYet =>
      validFrom != null && DateTime.now().isBefore(validFrom!);

  /// Usable right now, ignoring the order amount and the master
  /// coupon's isActive flag (both checked separately at checkout).
  bool get isUsableNow => !isUsed && !isExpired && !isNotStartedYet;

  /// Short label for the coupon value, e.g. "20% OFF" or "₹200 OFF".
  String get valueLabel {
    if (discountType == 'percent') {
      return '${_trim(discountValue)}% OFF';
    }
    return '₹${_trim(discountValue)} OFF';
  }

  /// Discount in rupees for an order of [subtotal]. Returns 0 when the
  /// order is below [minOrder]. Never more than the subtotal.
  double discountFor(double subtotal) {
    if (subtotal <= 0 || subtotal < minOrder) return 0;

    double discount;
    if (discountType == 'percent') {
      discount = subtotal * discountValue / 100;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }

    if (discount > subtotal) discount = subtotal;
    if (discount < 0) discount = 0;
    return (discount * 100).round() / 100;
  }

  // ------------------------------------------------------------
  // Parsing helpers (the website may save numbers/dates in
  // slightly different formats, so be forgiving).
  // ------------------------------------------------------------

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
