import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../coupons/datasources/coupon_datasource.dart';
import '../../coupons/models/user_coupon_model.dart';
import '../../coupons/widgets/coupon_card.dart';
import '../controllers/food_menu_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodMenuController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Your Cart",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.cart.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: "Your cart is empty.",
          );
        }

        final lines = controller.cart.values.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          // Cart lines, then the coupon section and the bill summary.
          itemCount: lines.length + 1,
          itemBuilder: (context, index) {
            if (index == lines.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CouponSection(controller: controller),
                    const SizedBox(height: 14),
                    _BillSummary(controller: controller),
                  ],
                ),
              );
            }
            final line = lines[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.8),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 12, color: AppColors.shadow, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\u20b9${line.item.price.toStringAsFixed(0)} each",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stepperButton(
                    icon: Icons.remove,
                    onTap: () => controller.removeFromCart(line.item),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${line.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _stepperButton(
                    icon: Icons.add,
                    onTap: () => controller.addToCart(line.item),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "\u20b9${line.lineTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.cart.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.deliveryAddress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Place Order  •  \u20b9${controller.payableTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

// ================================================================
// COUPON SECTION — "Apply coupon" row, or the applied coupon
// ================================================================

class _CouponSection extends StatelessWidget {
  final FoodMenuController controller;

  const _CouponSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final coupon = controller.appliedCoupon.value;
      final shortfall = controller.couponMinOrderShortfall;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: coupon != null
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.divider,
            width: coupon != null ? 1.2 : 0.8,
          ),
        ),
        child: coupon == null
            ? ListTile(
                onTap: () => _openCouponSheet(context, controller),
                leading: const Icon(Icons.local_offer_outlined,
                    color: AppColors.primary),
                title: const Text("Apply coupon"),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "'${coupon.code}' applied",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shortfall > 0
                                ? "Add ₹${shortfall.ceil()} more to use this coupon"
                                : "You save ₹${controller.couponDiscount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: shortfall > 0
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: controller.removeCoupon,
                      child: const Text("Remove"),
                    ),
                  ],
                ),
              ),
      );
    });
  }

  static void _openCouponSheet(
    BuildContext context,
    FoodMenuController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ApplyCouponSheet(controller: controller),
    );
  }
}

// ================================================================
// BILL SUMMARY — subtotal, coupon discount, total to pay
// ================================================================

class _BillSummary extends StatelessWidget {
  final FoodMenuController controller;

  const _BillSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Touch the reactive values so this rebuilds on cart/coupon change.
      controller.cart.length;
      final coupon = controller.appliedCoupon.value;
      final discount = controller.couponDiscount;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          children: [
            _row("Subtotal", "₹${controller.cartTotal.toStringAsFixed(0)}"),
            if (coupon != null && discount > 0) ...[
              const SizedBox(height: 8),
              _row(
                "Coupon (${coupon.code})",
                "− ₹${discount.toStringAsFixed(0)}",
                valueColor: AppColors.success,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _row(
              "To pay",
              "₹${controller.payableTotal.toStringAsFixed(0)}",
              bold: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    final style = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: AppColors.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: style)),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ?? style.color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// APPLY COUPON SHEET — type a code, or pick from your coupons
// ================================================================

class _ApplyCouponSheet extends StatefulWidget {
  final FoodMenuController controller;

  const _ApplyCouponSheet({required this.controller});

  @override
  State<_ApplyCouponSheet> createState() => _ApplyCouponSheetState();
}

class _ApplyCouponSheetState extends State<_ApplyCouponSheet> {
  final _codeController = TextEditingController();
  final _dataSource = CouponDataSource();

  late final Future<List<UserCoupon>> _couponsFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _couponsFuture = uid == null
        ? Future.value(<UserCoupon>[])
        : _dataSource.getUserCoupons(uid).then((list) => list
            .where((c) => c.isForFood && c.isUsableNow)
            .toList()
          ..sort((a, b) => b
              .discountFor(widget.controller.cartTotal)
              .compareTo(a.discountFor(widget.controller.cartTotal))));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleResult(String? error) async {
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      Get.snackbar(
        "Coupon applied",
        "You save ₹${widget.controller.couponDiscount.toStringAsFixed(0)} on this order.",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Apply coupon",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "Enter coupon code",
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        errorText: _error,
                        errorMaxLines: 3,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (value) async =>
                          _handleResult(await controller.applyCouponCode(value)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: controller.applyingCoupon.value
                              ? null
                              : () async => _handleResult(
                                    await controller
                                        .applyCouponCode(_codeController.text),
                                  ),
                          child: controller.applyingCoupon.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Apply"),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Your coupons",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<UserCoupon>>(
                future: _couponsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      "Could not load your coupons. You can still type a code above.",
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  final coupons = snapshot.data ?? [];
                  if (coupons.isEmpty) {
                    return const Text(
                      "You don't have any coupons for food right now.",
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  return Column(
                    children: coupons
                        .map((c) => CouponCard(
                              coupon: c,
                              onApply: controller.applyingCoupon.value
                                  ? null
                                  : () async => _handleResult(
                                        await controller.applyCoupon(c),
                                      ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
