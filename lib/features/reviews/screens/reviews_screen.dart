import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../experience/models/experience_model.dart';
import '../controllers/review_controller.dart';
import '../widgets/rating_summary.dart';
import '../widgets/review_card.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Experience meetup = Get.arguments as Experience;
    final controller = Get.put(ReviewController(meetupId: meetup.id), tag: meetup.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Reviews", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasError.value) {
          return const Center(child: Text("Couldn't load reviews. Pull to refresh."));
        }
        return RefreshIndicator(
          onRefresh: controller.loadReviews,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RatingSummary(avgRating: meetup.avgRating, reviewCount: meetup.reviewCount),
              const SizedBox(height: 20),
              if (controller.reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text("No reviews yet.", style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ...controller.reviews.map((r) => ReviewCard(review: r)),
            ],
          ),
        );
      }),
    );
  }
}