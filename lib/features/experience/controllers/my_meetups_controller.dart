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

  /// Cancels a meetup the current user created. Sets the meetup's
  /// `cancelled` flag (and now a `cancelReason`) in Firestore — soft
  /// cancel, the doc stays so participants' join history isn't wiped —
  /// and reloads the created list so the card updates to show a
  /// "Cancelled" state instead of disappearing from the tab.
  Future<void> cancelMeetup(String meetupId, {required String reason}) async {
    try {
      await experienceRepository.cancelMeetup(meetupId, reason: reason);
      await loadCreatedMeetups(); // refresh so the card shows as cancelled, not removed
    } catch (_) {
      Get.snackbar(
        "Couldn't cancel",
        "Something went wrong. Please try again.",
      );
      rethrow;
    }
  }

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
  // A meetup stays "Upcoming" for its entire duration — it only
  // moves to "Completed" once its end time has passed. Uses
  // effectiveEndDate so older meetups without a saved endDate
  // (2-hour default) still work correctly.
  // ===========================
  List<JoinRequest> get upcoming => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          r.meetup.effectiveEndDate.isAfter(DateTime.now()))
      .toList();

  // ===========================
  // Completed tab
  // Moves here once the meetup's end time (not start time) has
  // passed.
  // ===========================
  List<JoinRequest> get completed => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          r.meetup.effectiveEndDate.isBefore(DateTime.now()))
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