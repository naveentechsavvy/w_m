import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
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
          return const Center(
            child: Text(
              "Your cart is empty.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final lines = controller.cart.values.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final line = lines[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
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
                  "Place Order  •  \u20b9${controller.cartTotal.toStringAsFixed(0)}",
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
