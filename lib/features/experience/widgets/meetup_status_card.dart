import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../models/experience_model.dart';
import 'experience_card.dart';

/// Wraps the existing [ExperienceCard] with a status chip and an optional
/// trailing action button, so My Meetups tabs can reuse the exact same
/// card design used in Explore instead of building a new one.
class MeetupStatusCard extends StatelessWidget {
  final Experience experience;
  final String? statusLabel;
  final Color? statusColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;

  const MeetupStatusCard({
    super.key,
    required this.experience,
    this.statusLabel,
    this.statusColor,
    this.actionLabel,
    this.onActionTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExperienceCard(experience: experience, onTap: onTap),

        if (statusLabel != null)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (statusColor ?? AppColors.primary).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        if (actionLabel != null)
          Positioned(
            bottom: 18,
            right: 18,
            child: ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
