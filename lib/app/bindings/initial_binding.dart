import 'package:get/get.dart';

import '../../features/experience/controllers/join_requests_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Registered globally (not per-route) because JoinRequestsController
    // is shared by ExpDetailsScreen (Request to Join) and the upcoming
    // My Meetups screen (approve/reject incoming requests). lazyPut means
    // it isn't actually constructed until the first Get.find() call, so
    // there's no cost at startup for users who never open either screen.
    Get.lazyPut<JoinRequestsController>(() => JoinRequestsController());
  }
}
