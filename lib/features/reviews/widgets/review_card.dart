import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../models/review_model.dart';
import 'review_photo_grid.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year}";

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryTint,
                backgroundImage: (review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty)
                    ? NetworkImage(review.userPhotoUrl!)
                    : null,
                child: (review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating.round() ? Icons.star : Icons.star_border,
                            size: 14,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_formatDate(review.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: const TextStyle(color: AppColors.textPrimary, height: 1.4)),
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            ReviewPhotoGrid(photoUrls: review.photos),
          ],
        ],
      ),
    );
  }
}