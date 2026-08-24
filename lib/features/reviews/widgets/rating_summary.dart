import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class RatingSummary extends StatelessWidget {
  final double avgRating;
  final int reviewCount;

  const RatingSummary({
    super.key,
    required this.avgRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return const Text(
        "No reviews yet",
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star, color: Color(0xFFFFB300), size: 20),
        const SizedBox(width: 4),
        Text(
          avgRating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(width: 6),
        Text(
          "· $reviewCount ${reviewCount == 1 ? 'Review' : 'Reviews'}",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}