import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/experience_controller.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/experience_card.dart';
import '../widgets/bottom_navigation.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExperienceController());

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "👋 Good Evening",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Naveen",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.groups_outlined, size: 26),
                        color: AppColors.textPrimary,
                        tooltip: "My Meetups",
                        onPressed: () => Get.toNamed(AppRoutes.myMeetups),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 28),
                        color: AppColors.textPrimary,
                        tooltip: "Notifications",
                        onPressed: () => Get.toNamed(AppRoutes.notifications),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const HomeSearchBar(),

              const SizedBox(height: 25),

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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.toNamed(AppRoutes.createExperience),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Create",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}