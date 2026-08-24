import 'package:get/get.dart';

import '../controllers/experience_controller.dart';
import '../controllers/join_requests_controller.dart';

class ExperienceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JoinRequestsController>()) {
      Get.lazyPut<JoinRequestsController>(() => JoinRequestsController());
    }
    if (!Get.isRegistered<ExperienceController>()) {
      Get.lazyPut<ExperienceController>(() => ExperienceController());
    }
  }
}