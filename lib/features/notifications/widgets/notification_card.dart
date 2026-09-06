import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../models/notification_feed_item.dart';

class NotificationCard extends StatelessWidget {
  final NotificationFeedItem item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.item,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActionable = item.isJoinRequest || item.isFriendRequest;

    return GestureDetector(
      onTap: isActionable ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: item.isJoinRequest
            ? _buildJoinRequest()
            : item.isFriendRequest
                ? _buildFriendRequest()
                : _buildInfo(),
      ),
    );
  }

  Widget _buildJoinRequest() {
    final request = item.joinRequest!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryTint,
              child: Text(
                request.requesterName.isNotEmpty
                    ? request.requesterName[0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "wants to join \"${request.meetup.title}\"",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ignore",
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendRequest() {
    final fr = item.friendRequest!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryTint,
              child: Text(
                fr.senderName.isNotEmpty ? fr.senderName[0].toUpperCase() : "?",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fr.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "sent you a friend request",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ignore",
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final notif = item.notification!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.grey.shade100 : AppColors.primaryTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications,
            size: 20,
            color: notif.isRead ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notif.title,
                style: TextStyle(
                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notif.body,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!notif.isRead)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 8, top: 4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}