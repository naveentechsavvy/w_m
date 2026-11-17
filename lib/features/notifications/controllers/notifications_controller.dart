import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../experience/controllers/join_requests_controller.dart';
import '../../friends/controllers/friend_request_controller.dart';
import '../models/app_notification_model.dart';
import '../models/notification_feed_item.dart';
import '../repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository repository = NotificationRepository();
  late final JoinRequestsController joinRequestsController;
  late final FriendRequestController friendRequestController;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Reuse existing controllers if already in memory, otherwise create them.
    joinRequestsController = Get.isRegistered<JoinRequestsController>()
        ? Get.find<JoinRequestsController>()
        : Get.put(JoinRequestsController());

    friendRequestController = Get.isRegistered<FriendRequestController>()
        ? Get.find<FriendRequestController>()
        : Get.put(FriendRequestController());

    loadNotifications();
  }

  final notifications = <dynamic>[].obs; // AppNotification list from Firestore

  /// Shown on screen when notifications couldn't be loaded (missing
  /// index, rules, network...). Null when everything is fine.
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<AppNotification>>? _sub;

  /// Starts (or restarts) the live notifications listener and reloads
  /// join requests. Also used by pull-to-refresh. Completes once the
  /// first result (or error) has arrived.
  Future<void> loadNotifications() async {
    if (notifications.isEmpty) isLoading.value = true;
    errorMessage.value = null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      errorMessage.value = 'Please sign in again to see your notifications.';
      isLoading.value = false;
      return;
    }

    final firstResult = Completer<void>();
    void done() {
      isLoading.value = false;
      if (!firstResult.isCompleted) firstResult.complete();
    }

    await _sub?.cancel();
    _sub = repository.streamForUser(uid).listen(
      (result) {
        notifications.assignAll(result);
        errorMessage.value = null;
        done();
      },
      onError: (Object e) {
        debugPrint('[Notifications] Failed to load notifications: $e');
        errorMessage.value =
            'Could not load notifications. Pull down to try again.';
        done();
      },
    );

    try {
      await joinRequestsController.loadAll();
    } catch (e) {
      debugPrint('[Notifications] Failed to load join requests: $e');
    }

    await firstResult.future;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// Combined, time-sorted feed: pending join requests + friend requests
  /// + regular notifications.
  List<NotificationFeedItem> get feed {
    final items = <NotificationFeedItem>[
      ...joinRequestsController.pendingIncoming
          .map((r) => NotificationFeedItem.request(r)),
      ...friendRequestController.receivedWithSender
          .map((r) => NotificationFeedItem.friend(r)),
      ...notifications.map((n) => NotificationFeedItem.info(n)),
    ];
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  Future<void> approve(String requestId) => joinRequestsController.approve(requestId);

  Future<void> reject(String requestId) => joinRequestsController.reject(requestId);

  Future<void> acceptFriend(String requestId) =>
      friendRequestController.accept(requestId);

  Future<void> rejectFriend(String requestId) =>
      friendRequestController.reject(requestId);

  /// True when at least one notification is unread (drives the
  /// "Mark all as read" button).
  bool get hasUnread =>
      notifications.any((n) => (n as AppNotification).isRead == false);

  final RxBool markingAllRead = false.obs;

  /// Sets isRead = true on every unread notification (only that field,
  /// as the Firestore rules require). The live stream then confirms it.
  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || markingAllRead.value) return;

    markingAllRead.value = true;
    final previous = List<dynamic>.from(notifications);

    // Update the screen straight away.
    notifications.assignAll(
      notifications.map((n) => (n as AppNotification).copyWith(isRead: true)),
    );

    try {
      await repository.markAllAsRead(uid);
    } catch (e) {
      debugPrint('[Notifications] Failed to mark all as read: $e');
      notifications.assignAll(previous);
      Get.snackbar(
        'Could not update',
        'Could not mark notifications as read. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      markingAllRead.value = false;
    }
  }

  /// Swipe-to-delete. Removes the card straight away (Dismissible needs
  /// that), then deletes the Firestore doc. On failure the card comes
  /// back and a message is shown.
  Future<void> deleteNotification(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final removed = notifications.removeAt(index);

    try {
      await repository.delete(id);
    } catch (e) {
      debugPrint('[Notifications] Failed to delete $id: $e');
      notifications.insert(index.clamp(0, notifications.length), removed);
      Get.snackbar(
        'Could not delete',
        'Could not delete this notification. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  final RxBool clearingAll = false.obs;

  /// "Clear all": deletes all of this user's notifications. Pending
  /// join/friend requests aren't notifications, so they stay.
  Future<void> clearAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || clearingAll.value) return;

    clearingAll.value = true;
    final previous = List<dynamic>.from(notifications);
    notifications.clear();

    try {
      await repository.deleteAllForUser(uid);
    } catch (e) {
      debugPrint('[Notifications] Failed to clear all: $e');
      notifications.assignAll(previous);
      Get.snackbar(
        'Could not clear',
        'Could not clear notifications. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      clearingAll.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }
}