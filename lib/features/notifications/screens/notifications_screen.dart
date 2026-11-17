import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_feed_item.dart';
import '../utils/notification_time.dart';
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
        actions: [
          Obx(() {
            if (!controller.hasUnread) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: controller.markingAllRead.value
                    ? null
                    : controller.markAllAsRead,
                child: const Text(
                  "Mark all as read",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            );
          }),
          Obx(() {
            if (controller.notifications.isEmpty) {
              return const SizedBox.shrink();
            }
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: "More",
              enabled: !controller.clearingAll.value,
              onSelected: (value) {
                if (value == 'clear') _confirmClearAll(context, controller);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear', child: Text("Clear all")),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final feed = controller.feed;
        final error = controller.errorMessage.value;

        // Empty list or error: still allow pull-to-refresh.
        if (feed.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: error != null
                        ? EmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: error,
                          )
                        : const EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: "No notifications yet.",
                          ),
                  ),
                ],
              ),
            ),
          );
        }

        // Feed is already newest first. Insert a heading ("Today",
        // "Yesterday", "This week", "Earlier") before each new group.
        final entries = <Object>[];
        String? lastGroup;
        for (final item in feed) {
          final group = notificationGroupLabel(item.time);
          if (group != lastGroup) {
            entries.add(group);
            lastGroup = group;
          }
          entries.add(item);
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry is String) {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 8 : 12, bottom: 10),
                  child: Text(
                    entry,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }
              final item = entry as NotificationFeedItem;
              final card = NotificationCard(
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

              // Join/friend requests aren't notification docs (they need
              // Accept/Ignore), so only real notifications can be swiped.
              final notif = item.notification;
              if (notif == null) return card;

              return Dismissible(
                key: ValueKey('notif_${notif.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => controller.deleteNotification(notif.id),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.only(right: 24),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                child: card,
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    NotificationsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear all notifications?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              "Clear",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearAll();
  }
}