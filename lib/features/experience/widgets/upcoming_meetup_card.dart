import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/experience_model.dart';

class UpcomingMeetupCard extends StatelessWidget {
  final Experience experience;
  final VoidCallback onViewTap;

  const UpcomingMeetupCard({
    super.key,
    required this.experience,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(experience.title, style: AppTextStyles.heading3),
          const SizedBox(height: AppSizes.xs),
          Text(
            "${DateFormat('EEEE').format(experience.date)} • ${DateFormat('h:mm a').format(experience.date)}",
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSizes.xs),
          Text("${experience.joined} Participants", style: AppTextStyles.body),
          const SizedBox(height: AppSizes.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewTap,
              child: const Text(
                "View Meetup →",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}