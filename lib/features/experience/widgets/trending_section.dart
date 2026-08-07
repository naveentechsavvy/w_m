import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../experience/widgets/experience_card.dart';
import '../controllers/home_controller.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Trending Now", style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.trending.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 240,
                      child: ExperienceCard(experience: controller.trending[index]),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}