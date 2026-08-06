import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/experience_model.dart';
import '../models/join_request_model.dart';
import '../repositories/experience_repository.dart';
import 'join_requests_controller.dart';

/// Drives the "My Meetups" screen's 5 tabs. Backed by Firestore.
class MyMeetupsController extends GetxController {
  final JoinRequestsController joinRequestsController =
      Get.find<JoinRequestsController>();
  final ExperienceRepository experienceRepository = ExperienceRepository();

  final RxList<Experience> _createdMeetups = <Experience>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCreatedMeetups();
  }

  Future<void> loadCreatedMeetups() async {
    isLoading.value = true;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final result = await experienceRepository.getMeetupsByCreator(uid);
      _createdMeetups.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================
  // Created tab
  // ===========================
  List<Experience> get created => _createdMeetups;

  int pendingRequestCountFor(String meetupId) =>
      joinRequestsController.pendingIncomingForMeetup(meetupId).length;

  // ===========================
  // Joined tab
  // ===========================
  List<JoinRequest> get joined => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.pending ||
          r.status == JoinRequestStatus.approved)
      .toList();

  // ===========================
  // Upcoming tab
  // ===========================
  List<JoinRequest> get upcoming => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          r.meetup.date.isAfter(DateTime.now()))
      .toList();

  // ===========================
  // Completed tab
  // ===========================
  List<JoinRequest> get completed => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          r.meetup.date.isBefore(DateTime.now()))
      .toList();

  // ===========================
  // Cancelled tab
  // ===========================
  List<JoinRequest> get cancelled => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.cancelled ||
          r.status == JoinRequestStatus.rejected)
      .toList();
}