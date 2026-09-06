import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/app_config_controller.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/experience_controller.dart';
import '../widgets/category_chip.dart';
import '../widgets/experience_card.dart';
import '../widgets/bottom_navigation.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExperienceController());
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);
    final appConfigController = Get.isRegistered<AppConfigController>()
        ? Get.find<AppConfigController>()
        : Get.put(AppConfigController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  "assets/banners/hero_banner.jpg",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller.categories.map((cat) {
                        return CategoryChip(
                          title: cat,
                          selected: controller.selectedCategory.value == cat,
                          onTap: () => controller.changeCategory(cat),
                        );
                      }).toList(),
                    ),
                  )),

              const SizedBox(height: 30),

              const Text(
                "Nearby You",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Obx(() {
                return Column(
                  children: controller.nearby
                      .map((e) => ExperienceCard(experience: e))
                      .toList(),
                );
              }),

              const SizedBox(height: 30),

              const Text(
                "Trending Experiences",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Obx(() {
                return Column(
                  children: controller.trending
                      .map((e) => ExperienceCard(experience: e))
                      .toList(),
                );
              }),

              const SizedBox(height: 30),

              const Text(
                "Recommended For You",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Obx(() {
                return Column(
                  children: controller.recommended
                      .map((e) => ExperienceCard(experience: e))
                      .toList(),
                );
              }),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      floatingActionButton: Obx(() {
        // Same gating rule as ExperienceController.addExperience():
        // - premiumEnabled flag OFF -> everyone sees Create, regardless
        //   of subscription status (free-for-all launch period).
        // - premiumEnabled flag ON  -> only premium members see Create.
        // Previously this only checked isPremium, so turning the flag
        // off never actually revealed the button to free users — this
        // was the bug that hid Create even when it should show.
        final canCreate = !appConfigController.premiumEnabled.value ||
            subscriptionController.isPremium.value;

        if (!canCreate) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => Get.toNamed(AppRoutes.createExperience),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Create",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}