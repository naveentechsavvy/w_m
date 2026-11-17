import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/coupons_controller.dart';
import '../widgets/coupon_card.dart';

class MyCouponsScreen extends StatelessWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CouponsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Coupons'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: controller.error.value!,
          );
        }

        if (controller.coupons.isEmpty) {
          return const EmptyState(
            icon: Icons.local_offer_outlined,
            title: 'No coupons yet',
            message: 'Coupons you receive will show up here. '
                'Use them on your food orders.',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: controller.coupons.length,
              itemBuilder: (context, index) =>
                  CouponCard(coupon: controller.coupons[index]),
            ),
          ),
        );
      }),
    );
  }
}
