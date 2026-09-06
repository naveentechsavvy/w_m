import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../models/delivery_address_model.dart';
import '../models/food_item_model.dart';
import '../repositories/food_repository.dart';
import '../repositories/order_repository.dart';
import '../services/razorpay_payment_service.dart';

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
  }

  double get cartTotal =>
      cart.values.fold(0.0, (sum, line) => sum + line.lineTotal);

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
        'total': cartTotal,
        'status': 'placed',
        'deliveryAddress': address.toMap(),
        'createdAt': Timestamp.now(),
      });

      _pendingOrderId = orderRef.id;

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

  void _onPaymentSuccess() {
    placingOrder.value = false;
    final orderId = _pendingOrderId;
    cart.clear();
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