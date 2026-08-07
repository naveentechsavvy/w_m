import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../experience/widgets/experience_card.dart';
import '../controllers/home_controller.dart';

class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recommended For You", style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Obx(() => Column(
                children: controller.recommended
                    .map((exp) => ExperienceCard(experience: exp))
                    .toList(),
              )),
        ],
      ),
    );
  }
}