import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../experience/controllers/app_config_controller.dart';
import '../../experience/controllers/home_controller.dart';
import '../../experience/controllers/subscription_controller.dart';
import '../../experience/widgets/bottom_navigation.dart';
import '../../experience/widgets/home_search_bar.dart';
import '../../experience/widgets/upcoming_meetup_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);
    final appConfigController = Get.isRegistered<AppConfigController>()
        ? Get.find<AppConfigController>()
        : Get.put(AppConfigController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.allExperiences.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadHome,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                        color: AppColors.primary,
                        tooltip: "Back to Choice",
                        onPressed: () => Get.offNamed(AppRoutes.choice),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.groups_outlined, size: 26),
                            color: AppColors.primary,
                            tooltip: "My Meetups",
                            onPressed: () => Get.toNamed(AppRoutes.myMeetups),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none, size: 26),
                            color: AppColors.primary,
                            tooltip: "Notifications",
                            onPressed: () => Get.toNamed(AppRoutes.notifications),
                          ),
                          IconButton(
                            icon: const Icon(Icons.account_circle_outlined, size: 26),
                            color: AppColors.primary,
                            tooltip: "Profile",
                            onPressed: () => Get.toNamed(AppRoutes.profile),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Obx(() => HomeSearchBar(
                        showVoiceIcon: true,
                        isListening: controller.isListening.value,
                        searchController: controller.searchTextController,
                        onVoiceTap: () {
                          if (controller.isListening.value) {
                            controller.stopVoiceSearch();
                          } else {
                            controller.startVoiceSearch();
                          }
                        },
                      )),
                  const SizedBox(height: AppSizes.lg),
                  // AppTextStyles.heading3 is no longer a compile-time
                  // constant (GoogleFonts.poppins() isn't const), so this
                  // Text can't be const anymore.
                  Text(
                    "Welcome to Weekend Masti 👋",
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Premium upgrade banner — only shown to free members,
                  // AND only when the admin-controlled premiumEnabled
                  // flag (Firestore: app_config/settings) is true.
                  // Replaces the old "Upgrade to Premium" FAB on Explore.
                  Obx(() {
                    if (!appConfigController.premiumEnabled.value) {
                      return const SizedBox.shrink();
                    }
                    if (subscriptionController.isPremium.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.lg),
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.premiumPlan),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                "👑",
                                style: TextStyle(fontSize: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Go Premium",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Create your own meetups and invite others",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Same reason as above — no const.
                  Text("My Upcoming Meetup", style: AppTextStyles.heading3),
                  const SizedBox(height: AppSizes.sm),
                  controller.upcomingMeetup == null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          // Column itself can't be const either, since one
                          // of its children (below) uses AppTextStyles.
                          child: Column(
                            children: [
                              Text("No upcoming meetups", style: AppTextStyles.heading3),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                "Explore something fun this weekend!",
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : UpcomingMeetupCard(
                          experience: controller.upcomingMeetup!,
                          onViewTap: () => Get.toNamed(
                            AppRoutes.experienceDetails,
                            arguments: controller.upcomingMeetup,
                          ),
                        ),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }
}