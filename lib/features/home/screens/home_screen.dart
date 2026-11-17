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

    // Home replaces the Choice screen (Get.offNamed), so it's the only
    // screen on the stack and the phone's back button would close the
    // app. Go back to Choice instead, same as the back arrow above.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offNamed(AppRoutes.choice);
      },
      child: Scaffold(
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
                  // Top bar: back arrow on the left (goes to Choice, same
                  // as the phone's back button), 3 action icons on the
                  // right, all vertically centred.
                  SizedBox(
                    height: 56,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const BackButtonIcon(),
                          color: AppColors.textPrimary,
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints.tightFor(width: 44, height: 44),
                          onPressed: () => Get.offNamed(AppRoutes.choice),
                        ),
                        const Spacer(),
                        _HeaderIconButton(
                          icon: Icons.groups_outlined,
                          tooltip: "My Meetups",
                          onPressed: () => Get.toNamed(AppRoutes.myMeetups),
                        ),
                        const SizedBox(width: 10),
                        _HeaderIconButton(
                          icon: Icons.notifications_none,
                          tooltip: "Notifications",
                          onPressed: () => Get.toNamed(AppRoutes.notifications),
                        ),
                        const SizedBox(width: 10),
                        _HeaderIconButton(
                          icon: Icons.account_circle_outlined,
                          tooltip: "Profile",
                          onPressed: () => Get.toNamed(AppRoutes.profile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 32),
                  // One line only: on narrow phones the text scales down a
                  // little instead of pushing the 👋 onto its own line.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Welcome to Weekend Masti 👋",
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextStyles.heading2.copyWith(fontSize: 21),
                    ),
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
      ),
    );
  }
}

/// Round icon button with a soft primary-tint background (no border),
/// used in the home header so all actions share the same size, shape
/// and spacing.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  static const double _iconSize = 23;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primaryTint,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: _iconSize, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}