import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../coupons/datasources/coupon_datasource.dart';
import '../../coupons/models/user_coupon_model.dart';
import '../models/delivery_address_model.dart';
import '../models/food_item_model.dart';
import '../repositories/food_repository.dart';
import '../repositories/order_repository.dart';
import '../services/razorpay_payment_service.dart';
import '../../../core/services/activity_logger.dart';

/// One cart line: a food item plus how many the user wants.
class CartLine {
  final FoodItem item;
  int quantity;
  CartLine({required this.item, this.quantity = 1});

  double get lineTotal => item.price * quantity;
}

class FoodMenuController extends GetxController {
  final FoodRepository _repository = FoodRepository();
  final OrderRepository _orderRepository = OrderRepository();
  late final RazorpayPaymentService _paymentService;

  /// TEMP: while Razorpay isn't wired to real keys yet (and doesn't
  /// support Flutter Web at all), orders are marked 'placed' directly
  /// instead of going through checkout. Flip to false once real
  /// payment is ready — no screen code needs to change.
  static const bool _dummyPaymentMode = true;

  final RxList<FoodItem> items = <FoodItem>[].obs;
  final RxBool isReady = false.obs;

  /// Current text in the search box on the Food screen.
  final RxString searchQuery = ''.obs;

  /// 'All' or an actual category name from Firestore.
  final RxString selectedFilter = 'All'.obs;

  /// Cart keyed by item id so adding the same item twice increments
  /// quantity instead of creating a duplicate line.
  final RxMap<String, CartLine> cart = <String, CartLine>{}.obs;

  final RxBool placingOrder = false.obs;

  // ------------------------------------------------------------
  // COUPON (max 1 per order)
  // ------------------------------------------------------------
  final CouponDataSource _couponDataSource = CouponDataSource();

  /// The coupon applied to the current cart, if any.
  final Rxn<UserCoupon> appliedCoupon = Rxn<UserCoupon>();

  /// True while a coupon code is being checked.
  final RxBool applyingCoupon = false.obs;

  /// Set once the user submits the Address screen; carried through to
  /// placeOrder() so the whole Cart -> Address -> Payment flow shares
  /// this one controller instance.
  DeliveryAddress? deliveryAddress;

  String? _pendingOrderId;

  StreamSubscription<List<FoodItem>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _paymentService = RazorpayPaymentService();
    _paymentService.onSuccess = _onPaymentSuccess;
    _paymentService.onFailure = _onPaymentFailure;

    _sub = _repository.streamAvailableItems().listen((list) {
      items.assignAll(list);
      isReady.value = true;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _paymentService.dispose();
    super.onClose();
  }

  /// Items grouped by category, each group's items sorted by name.
  Map<String, List<FoodItem>> get groupedByCategory {
    final Map<String, List<FoodItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return grouped;
  }

  /// All category names in the menu, for building filter chips.
  List<String> get allCategories => groupedByCategory.keys.toList()..sort();

  /// Applies search text + selectedFilter (All or a real category).
  Map<String, List<FoodItem>> get filteredGroupedByCategory {
    final query = searchQuery.value.trim().toLowerCase();
    final filter = selectedFilter.value;

    final Map<String, List<FoodItem>> grouped = {};
    for (final item in items) {
      if (filter != 'All' && item.category != filter) continue;

      final matches = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      if (!matches) continue;

      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return grouped;
  }

  int quantityOf(String itemId) => cart[itemId]?.quantity ?? 0;

  void addToCart(FoodItem item) {
    final existing = cart[item.id];
    if (existing != null) {
      existing.quantity += 1;
      cart.refresh();
    } else {
      cart[item.id] = CartLine(item: item);
    }
  }

  void removeFromCart(FoodItem item) {
    final existing = cart[item.id];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      cart.remove(item.id);
    } else {
      existing.quantity -= 1;
      cart.refresh();
    }
    if (cart.isEmpty) appliedCoupon.value = null;
  }

  /// Sum of all cart lines BEFORE any coupon (the order subtotal).
  double get cartTotal =>
      cart.values.fold(0.0, (sum, line) => sum + line.lineTotal);

  /// Coupon discount for the current cart. 0 when no coupon is applied
  /// or the cart is below the coupon's minimum order.
  double get couponDiscount =>
      appliedCoupon.value?.discountFor(cartTotal) ?? 0;

  /// Amount the customer actually pays (subtotal - discount).
  double get payableTotal {
    final total = cartTotal - couponDiscount;
    return total < 0 ? 0 : (total * 100).round() / 100;
  }

  /// How much more the cart needs to reach the applied coupon's
  /// minimum order. 0 when there's no shortfall.
  double get couponMinOrderShortfall {
    final coupon = appliedCoupon.value;
    if (coupon == null || cartTotal >= coupon.minOrder) return 0;
    return coupon.minOrder - cartTotal;
  }

  /// Applies a coupon by its code. Returns an error message to show,
  /// or null on success.
  Future<String?> applyCouponCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'Please enter a coupon code.';

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Please sign in again to use coupons.';

    applyingCoupon.value = true;
    try {
      final all = await _couponDataSource.getUserCoupons(uid);
      final matches =
          all.where((c) => c.code.trim().toUpperCase() == code).toList();
      if (matches.isEmpty) return 'This coupon code is not valid for you.';

      // Prefer a usable copy if the same code was given more than once.
      final coupon = matches.firstWhere(
        (c) => c.isUsableNow && c.isForFood,
        orElse: () => matches.first,
      );
      return await _applyChecked(coupon);
    } catch (_) {
      return 'Could not check this coupon. Please try again.';
    } finally {
      applyingCoupon.value = false;
    }
  }

  /// Applies a coupon picked from the list. Returns an error message,
  /// or null on success.
  Future<String?> applyCoupon(UserCoupon coupon) async {
    applyingCoupon.value = true;
    try {
      return await _applyChecked(coupon);
    } catch (_) {
      return 'Could not check this coupon. Please try again.';
    } finally {
      applyingCoupon.value = false;
    }
  }

  void removeCoupon() => appliedCoupon.value = null;

  Future<String?> _applyChecked(UserCoupon coupon) async {
    final error = await _validateCoupon(coupon, cartTotal);
    if (error == null) appliedCoupon.value = coupon;
    return error;
  }

  /// All coupon checks in one place. Returns an error message or null.
  Future<String?> _validateCoupon(UserCoupon coupon, double subtotal) async {
    if (!coupon.isForFood) {
      return 'This coupon can\'t be used on food orders.';
    }
    if (coupon.isUsed) return 'This coupon has already been used.';
    if (coupon.isNotStartedYet) return 'This coupon isn\'t active yet.';
    if (coupon.isExpired) return 'This coupon has expired.';
    if (subtotal < coupon.minOrder) {
      final more = (coupon.minOrder - subtotal).ceil();
      return 'Add ₹$more more to use this coupon '
          '(minimum order ₹${coupon.minOrder.toStringAsFixed(0)}).';
    }
    if (!await _couponDataSource.isCouponActive(coupon.couponId)) {
      return 'This coupon is no longer active.';
    }
    if (coupon.discountFor(subtotal) <= 0) {
      return 'This coupon gives no discount on this order.';
    }
    if (!_dummyPaymentMode && subtotal - coupon.discountFor(subtotal) < 1) {
      return 'Order total after discount must be at least ₹1.';
    }
    return null;
  }

  int get cartItemCount =>
      cart.values.fold(0, (sum, line) => sum + line.quantity);

  /// Called from the Address screen once the user submits their
  /// delivery details. Creates the Firestore order, then either
  /// marks it placed directly (dummy mode) or hands off to Razorpay
  /// checkout (real mode, not available on Flutter Web).
  Future<void> confirmAddressAndPay(DeliveryAddress address) async {
    if (cart.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Get.snackbar(
        'Not signed in',
        'Please sign in again to place an order.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    deliveryAddress = address;
    placingOrder.value = true;

    // Re-check the applied coupon with fresh data right before ordering
    // (it may have been used on another device, expired, or switched
    // off by the admin since it was applied).
    UserCoupon? coupon = appliedCoupon.value;
    if (coupon != null) {
      String? couponError;
      try {
        final fresh = await _couponDataSource.getUserCoupon(coupon.id);
        if (fresh == null) {
          couponError = 'This coupon is no longer available.';
        } else {
          coupon = fresh;
          couponError = await _validateCoupon(fresh, cartTotal);
        }
      } catch (_) {
        couponError = 'Could not check your coupon. Please try again.';
      }

      if (couponError != null) {
        placingOrder.value = false;
        Get.snackbar(
          'Coupon not applied',
          '$couponError Remove the coupon or update your cart, then try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final subtotal = cartTotal;
    final discount = coupon?.discountFor(subtotal) ?? 0;
    final total = ((subtotal - discount) * 100).round() / 100;

    try {
      final orderRef =
          await FirebaseFirestore.instance.collection('orders').add({
        'userId': uid,
        'items': cart.values
            .map((line) => {
                  'itemId': line.item.id,
                  'name': line.item.name,
                  'price': line.item.price,
                  'quantity': line.quantity,
                })
            .toList(),
        'subtotal': subtotal,
        'discount': discount,
        // Amount actually charged (after coupon). Razorpay reads this.
        'total': total,
        'status': 'placed',
        'deliveryAddress': address.toMap(),
        'createdAt': Timestamp.now(),
        if (coupon != null) ...{
          'couponCode': coupon.code,
          'couponId': coupon.couponId,
          'userCouponId': coupon.id,
          // Lets the redeemCouponOnOrderPaid Cloud Function mark the
          // coupon used for test-mode orders, which never become 'paid'.
          'paymentMode': _dummyPaymentMode ? 'test' : 'razorpay',
        },
      });

      _pendingOrderId = orderRef.id;

      // Admin website activity log (best-effort, doesn't wait).
      final totalLabel = total.toStringAsFixed(total % 1 == 0 ? 0 : 2);
      activityUserName(uid, fallback: address.name).then((userName) => logActivity(
            userId: uid,
            userName: userName,
            type: ActivityType.foodOrdered,
            title: 'Ordered food (₹$totalLabel)',
          ));

      // Free (Spark) plan: Cloud Functions don't run, so the app marks
      // the coupon used itself, right after the order is saved.
      if (coupon != null) {
        await _markCouponUsed(coupon, orderRef.id);
      }

      if (_dummyPaymentMode) {
        // Simulate gateway delay, then confirm the order (no real charge).
        await Future.delayed(const Duration(milliseconds: 800));
        _onPaymentSuccess();
      } else {
        await _paymentService.startCheckout(
          firestoreOrderId: orderRef.id,
          userName: address.name,
          userPhone: address.phone,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Order Failed',
        'Something went wrong while starting checkout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      placingOrder.value = false;
    }
  }

  /// Uses up one use of [coupon] for [orderId]. Never throws: if the
  /// update fails (rules, network, timeout) it is only logged, so the
  /// order itself is never cancelled because of the coupon.
  Future<void> _markCouponUsed(UserCoupon coupon, String orderId) async {
    try {
      final updated = await _couponDataSource
          .redeemForOrder(userCouponId: coupon.id, orderId: orderId)
          .timeout(const Duration(seconds: 10));
      debugPrint(updated
          ? '[Coupon] ${coupon.code} marked used for order $orderId'
          : '[Coupon] ${coupon.code} not updated (no uses left or already counted)');
    } catch (e) {
      debugPrint('[Coupon] Failed to mark ${coupon.code} used for order $orderId: $e');
    }
  }

  void _onPaymentSuccess() {
    placingOrder.value = false;
    final orderId = _pendingOrderId;
    cart.clear();
    appliedCoupon.value = null;
    _pendingOrderId = null;
    deliveryAddress = null;

    Get.offNamed(AppRoutes.orderSuccess, arguments: {'orderId': orderId});
  }

  void _onPaymentFailure(String message) {
    placingOrder.value = false;
    Get.snackbar(
      'Payment Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}