import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../experience/controllers/home_controller.dart';
import '../../experience/widgets/bottom_navigation.dart';
import '../../experience/widgets/home_search_bar.dart';
import '../../experience/widgets/upcoming_meetup_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

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
                      Expanded(
                        child: Text(
                          "Good Morning, ${controller.userName} 👋",
                          style: AppTextStyles.heading3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.groups_outlined, size: 26),
                        color: AppColors.textPrimary,
                        tooltip: "My Meetups",
                        onPressed: () => Get.toNamed(AppRoutes.myMeetups),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 26),
                        color: AppColors.textPrimary,
                        tooltip: "Notifications",
                        onPressed: () => Get.toNamed(AppRoutes.notifications),
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle_outlined, size: 26),
                        color: AppColors.textPrimary,
                        tooltip: "Profile",
                        onPressed: () => Get.toNamed(AppRoutes.profile),
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
                  const Text(
                    "Welcome to Weekend Masti 👋",
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const Text("My Upcoming Meetup", style: AppTextStyles.heading3),
                  const SizedBox(height: AppSizes.sm),
                  controller.upcomingMeetup == null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                          child: const Column(
                            children: [
                              Text("No upcoming meetups", style: AppTextStyles.heading3),
                              SizedBox(height: AppSizes.xs),
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