import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Notifications",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final feed = controller.feed;

        if (feed.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                "No notifications yet.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: feed.length,
            itemBuilder: (context, index) {
              final item = feed[index];
              return NotificationCard(
                item: item,
                onApprove: item.isJoinRequest
                    ? () => controller.approve(item.joinRequest!.id)
                    : item.isFriendRequest
                        ? () => controller.acceptFriend(item.friendRequest!.request.id)
                        : null,
                onReject: item.isJoinRequest
                    ? () => controller.reject(item.joinRequest!.id)
                    : item.isFriendRequest
                        ? () => controller.rejectFriend(item.friendRequest!.request.id)
                        : null,
                onTap: (!item.isJoinRequest && !item.isFriendRequest)
                    ? () => controller.markAsRead(item.notification!.id)
                    : null,
              );
            },
          ),
        );
      }),
    );
  }
}