import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_coupon_model.dart';

/// Read-only access to coupons. The app never writes to `coupons` or
/// `user_coupons`; the admin website creates them and the
/// `redeemCouponOnOrderPaid` Cloud Function marks them used.
class CouponDataSource {
  final _userCoupons = FirebaseFirestore.instance.collection('user_coupons');
  final _coupons = FirebaseFirestore.instance.collection('coupons');

  /// Live list of every coupon given to [uid] (all types, all statuses).
  /// Single where() so no composite index is needed.
  Stream<List<UserCoupon>> streamUserCoupons(String uid) {
    return _userCoupons
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(UserCoupon.fromDoc).toList());
  }

  /// One-time fetch of every coupon given to [uid].
  Future<List<UserCoupon>> getUserCoupons(String uid) async {
    final snap = await _userCoupons.where('userId', isEqualTo: uid).get();
    return snap.docs.map(UserCoupon.fromDoc).toList();
  }

  /// Fresh copy of one user coupon, or null if it no longer exists.
  Future<UserCoupon?> getUserCoupon(String userCouponId) async {
    final doc = await _userCoupons.doc(userCouponId).get();
    if (!doc.exists) return null;
    return UserCoupon.fromDoc(doc);
  }

  /// True only when the master coupon `coupons/{couponId}` exists and
  /// has isActive == true (the admin can switch a coupon off).
  Future<bool> isCouponActive(String couponId) async {
    if (couponId.isEmpty) return false;
    final doc = await _coupons.doc(couponId).get();
    return doc.exists && doc.data()?['isActive'] == true;
  }

  /// Marks one use of a coupon for [orderId], in a transaction.
  ///
  /// Writes ONLY these 4 fields (Firestore rules reject anything else):
  ///   usesLeft (−1), status ('used' at 0, else 'assigned'),
  ///   usedAt (server time), orderId.
  ///
  /// Returns false, without writing, when the coupon is missing, has
  /// no uses left, is already 'used', or was already redeemed for this
  /// same order. Throws if Firestore rejects the write (e.g. outside
  /// validFrom..validTo or the coupon was switched off) — the caller
  /// decides how to handle that.
  Future<bool> redeemForOrder({
    required String userCouponId,
    required String orderId,
  }) {
    final ref = _userCoupons.doc(userCouponId);

    return FirebaseFirestore.instance.runTransaction<bool>((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return false;

      final data = snap.data()!;
      if (data['orderId'] == orderId) return false; // already counted

      final rawUses = data['usesLeft'];
      final int usesLeft =
          rawUses is num ? rawUses.toInt() : int.tryParse('$rawUses') ?? 0;
      if (usesLeft <= 0 || data['status'] == 'used') return false;

      final newUsesLeft = usesLeft - 1;
      txn.update(ref, {
        'usesLeft': newUsesLeft,
        'status': newUsesLeft == 0 ? 'used' : 'assigned',
        'usedAt': FieldValue.serverTimestamp(),
        'orderId': orderId,
      });
      return true;
    });
  }
}
