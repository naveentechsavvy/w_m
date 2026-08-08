import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../experience/controllers/join_requests_controller.dart';
import '../models/notification_feed_item.dart';
import '../repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository repository = NotificationRepository();
  late final JoinRequestsController joinRequestsController;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Reuse the existing controller if already in memory, otherwise create it.
    joinRequestsController = Get.isRegistered<JoinRequestsController>()
        ? Get.find<JoinRequestsController>()
        : Get.put(JoinRequestsController());
    loadNotifications();
  }

  final notifications = <dynamic>[].obs; // AppNotification list from Firestore

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final result = await repository.getForUser(uid);
      notifications.assignAll(result);
      await joinRequestsController.loadAll();
    } finally {
      isLoading.value = false;
    }
  }

  /// Combined, time-sorted feed: pending join requests + regular notifications.
  List<NotificationFeedItem> get feed {
    final items = <NotificationFeedItem>[
      ...joinRequestsController.pendingIncoming
          .map((r) => NotificationFeedItem.request(r)),
      ...notifications.map((n) => NotificationFeedItem.info(n)),
    ];
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  Future<void> approve(String requestId) => joinRequestsController.approve(requestId);

  Future<void> reject(String requestId) => joinRequestsController.reject(requestId);

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }
}