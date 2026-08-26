import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --------------------------------------------------
              // FIND WHAT'S HAPPENING
              // --------------------------------------------------

              _ChoiceCard(
                icon: Icons.explore_rounded,
                title: "Find What's Happening\nIn Your City",
                subtitle:
                    'Discover trekking, cricket, coffee meets, '
                    'cycling and more happening around you.',
                buttonText: 'Explore',
                isPrimary: true,
                onTap: () {
                  Get.offNamed(AppRoutes.home);
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // ORDER FOOD
              // --------------------------------------------------

              _ChoiceCard(
                icon: Icons.restaurant_rounded,
                title: 'Order Food For\nYour Weekend',
                subtitle:
                    'Planning your own gathering? Order food '
                    'easily from nearby restaurants.',
                buttonText: 'Order Food',
                isPrimary: false,
                onTap: () {
                  Get.snackbar(
                    'Coming Soon',
                    'Food Ordering will be available in Sprint 4',
                    snackPosition: SnackPosition.BOTTOM,
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

// ================================================================
// CHOICE CARD
// ================================================================

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.12)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(
                isPrimary ? 0.12 : 0.08,
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              icon,
              size: 31,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 22),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 22),

          // Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPrimary ? AppColors.primary : Colors.white,
                foregroundColor:
                    isPrimary ? Colors.white : AppColors.primary,
                elevation: 0,
                side: isPrimary
                    ? BorderSide.none
                    : BorderSide(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}