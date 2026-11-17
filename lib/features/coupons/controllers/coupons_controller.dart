import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../datasources/coupon_datasource.dart';
import '../models/user_coupon_model.dart';

/// Drives the My Coupons screen.
class CouponsController extends GetxController {
  final CouponDataSource _dataSource = CouponDataSource();

  final RxList<UserCoupon> coupons = <UserCoupon>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  StreamSubscription<List<UserCoupon>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _sub = _dataSource.streamUserCoupons(uid).listen(
      (list) {
        // Food/all only — meetup coupons are hidden while meetups are free.
        final visible = list.where((c) => c.isForFood).toList()
          ..sort(_compare);
        coupons.assignAll(visible);
        error.value = null;
        isLoading.value = false;
      },
      onError: (e) {
        error.value = 'Could not load your coupons. Please try again.';
        isLoading.value = false;
      },
    );
  }

  /// Usable coupons first (soonest expiry first), then the rest.
  static int _compare(UserCoupon a, UserCoupon b) {
    if (a.isUsableNow != b.isUsableNow) return a.isUsableNow ? -1 : 1;
    final aEnd = a.validTo ?? DateTime(9999);
    final bEnd = b.validTo ?? DateTime(9999);
    return aEnd.compareTo(bEnd);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
