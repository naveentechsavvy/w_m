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
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(
                child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderIconButton(
                        icon: Icons.arrow_back_ios_new,
                        iconSize: 18,
                        tooltip: "Back to Choice",
                        onPressed: () => Get.offNamed(AppRoutes.choice),
                      ),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: Icons.groups_outlined,
                            tooltip: "My Meetups",
                            onPressed: () => Get.toNamed(AppRoutes.myMeetups),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.notifications_none,
                            tooltip: "Notifications",
                            onPressed: () => Get.toNamed(AppRoutes.notifications),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: Icons.account_circle_outlined,
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
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
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
                  const SizedBox(height: 12),
                  controller.upcomingMeetup == null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            border: Border.all(color: AppColors.divider, width: 0.8),
                          ),
                          // Column itself can't be const either, since one
                          // of its children (below) uses AppTextStyles.
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryTint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_available_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),
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
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }
}

/// Rounded, outlined icon button used in the home header so all
/// header actions share the same size, shape and spacing.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: iconSize, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}