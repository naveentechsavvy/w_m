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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
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
          ],
        ),

        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onActionTap,
                icon: const Icon(Icons.close, size: 16),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}