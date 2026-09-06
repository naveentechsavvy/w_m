import 'package:get/get.dart';

import '../controllers/experience_controller.dart';
import '../controllers/join_requests_controller.dart';
import '../../friends/controllers/friend_request_controller.dart';

class ExperienceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JoinRequestsController>()) {
      Get.lazyPut<JoinRequestsController>(() => JoinRequestsController());
    }
    if (!Get.isRegistered<ExperienceController>()) {
      Get.lazyPut<ExperienceController>(() => ExperienceController());
    }
    if (!Get.isRegistered<FriendRequestController>()) {
      Get.lazyPut<FriendRequestController>(() => FriendRequestController());
    }
  }
}