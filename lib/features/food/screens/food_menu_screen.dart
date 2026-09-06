import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/food_item_model.dart';
import '../repositories/food_repository.dart';

/// One cart line: a food item plus how many the user wants.
class CartLine {
  final FoodItem item;
  int quantity;
  CartLine({required this.item, this.quantity = 1});

  double get lineTotal => item.price * quantity;
}

class FoodMenuController extends GetxController {
  final FoodRepository _repository = FoodRepository();

  final RxList<FoodItem> items = <FoodItem>[].obs;
  final RxBool isReady = false.obs;

  /// Cart keyed by item id so adding the same item twice increments
  /// quantity instead of creating a duplicate line.
  final RxMap<String, CartLine> cart = <String, CartLine>{}.obs;

  final RxBool placingOrder = false.obs;

  StreamSubscription<List<FoodItem>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamAvailableItems().listen((list) {
      items.assignAll(list);
      isReady.value = true;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Items grouped by category, each group's items sorted by name.
  /// Done client-side (not via Firestore orderBy) to avoid needing a
  /// composite index for a query that doesn't otherwise need one.
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

  /// Writes a single order document. No payment step yet — matches the
  /// existing plan to build the UI now and wire Razorpay in later.
  Future<void> placeOrder() async {
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

    placingOrder.value = true;
    try {
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
        'createdAt': Timestamp.now(),
      });

      cart.clear();

      Get.snackbar(
        'Order Placed',
        'Your food order has been placed successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Order Failed',
        'Something went wrong while placing your order. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      placingOrder.value = false;
    }
  }
}
