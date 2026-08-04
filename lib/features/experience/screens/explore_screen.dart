import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../controllers/experience_controller.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/experience_card.dart';

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

              const Text(
                "👋 Good Evening",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Naveen",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
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

              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoryChip(title: "Adventure", selected: true),
                    CategoryChip(title: "Coffee"),
                    CategoryChip(title: "Cricket"),
                    CategoryChip(title: "Music"),
                    CategoryChip(title: "Cycling"),
                    CategoryChip(title: "Food"),
                  ],
                ),
              ),

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
                  children: controller.experiences
                      .map((e) => ExperienceCard(experience: e))
                      .toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}