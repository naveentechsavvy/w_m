import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../experience/widgets/experience_card.dart';
import '../controllers/home_controller.dart';

class NearbySection extends StatelessWidget {
  const NearbySection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nearby You", style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Obx(() => Column(
                children: controller.nearby
                    .map((exp) => ExperienceCard(experience: exp))
                    .toList(),
              )),
        ],
      ),
    );
  }
}