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
      padding: const EdgeInsets.all(AppSizes.md + 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: AppColors.shadow,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            experience.title,
            style: AppTextStyles.heading3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                "${DateFormat('EEEE').format(experience.date)} • ${DateFormat('h:mm a').format(experience.date)}",
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.people_outline,
            text: "${experience.joined} Participants",
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewTap,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text("View Meetup"),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
