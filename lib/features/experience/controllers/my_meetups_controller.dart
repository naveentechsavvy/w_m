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
  // A cancelled meetup that nobody joined disappears from this list
  // entirely — nobody was affected, so there's nothing to show. A
  // cancelled meetup that DID have participants still shows here with
  // the "Cancelled" badge, so the organizer can see what happened to
  // something people had joined.
  List<Experience> get created =>
      _createdMeetups.where((e) => !(e.cancelled && e.joined == 0)).toList();

  int pendingRequestCountFor(String meetupId) =>
      joinRequestsController.pendingIncomingForMeetup(meetupId).length;

  /// Cancels a meetup the current user created.
  ///
  /// - If nobody has joined yet, the meetup is deleted outright — there's
  ///   no one to notify, so there's nothing worth keeping a record of,
  ///   and it should simply disappear rather than linger anywhere.
  /// - If people have already joined, it's soft-cancelled instead (the
  ///   Firestore doc stays, `cancelled` + `cancelReason` are set) so
  ///   participants can still see it in their own Cancelled tab along
  ///   with the organizer's reason, and their join history isn't wiped.
  Future<void> cancelMeetup(String meetupId, {required String reason}) async {
    try {
      final meetup =
          _createdMeetups.firstWhereOrNull((e) => e.id == meetupId);
      final hasParticipants = (meetup?.joined ?? 0) > 0;

      if (hasParticipants) {
        await experienceRepository.cancelMeetup(meetupId, reason: reason);
      } else {
        await experienceRepository.deleteMeetup(meetupId);
      }

      await loadCreatedMeetups(); // refresh so the card updates or disappears
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
  // FIX: previously showed ANY pending/approved request regardless of
  // whether the organizer had cancelled the meetup — which meant a
  // joined-then-cancelled meetup appeared in BOTH this tab AND the
  // Cancelled tab at the same time. Now excludes cancelled meetups,
  // same as Upcoming/Completed already did, so a cancelled meetup only
  // ever shows in exactly one place: Cancelled.
  // ===========================
  List<JoinRequest> get joined => joinRequestsController.myRequests
      .where((r) =>
          (r.status == JoinRequestStatus.pending ||
              r.status == JoinRequestStatus.approved) &&
          !r.meetup.cancelled)
      .toList();

  // ===========================
  // Upcoming tab
  // Excludes meetups the organizer has cancelled — those move to the
  // Cancelled tab instead (with the organizer's reason), regardless of
  // how much time was originally left on the clock.
  // ===========================
  List<JoinRequest> get upcoming => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          !r.meetup.cancelled &&
          r.meetup.effectiveEndDate.isAfter(DateTime.now()))
      .toList();

  // ===========================
  // Completed tab
  // Same cancellation exclusion as Upcoming.
  // ===========================
  List<JoinRequest> get completed => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.approved &&
          !r.meetup.cancelled &&
          r.meetup.effectiveEndDate.isBefore(DateTime.now()))
      .toList();

  // ===========================
  // Cancelled tab
  // Covers the participant's OWN join request being cancelled/rejected,
  // AND the case where the request was approved but the ORGANIZER
  // cancelled the whole meetup afterward. The UI (meetup_status_card)
  // is responsible for showing the organizer's cancelReason so the
  // participant knows why.
  // ===========================
  List<JoinRequest> get cancelled => joinRequestsController.myRequests
      .where((r) =>
          r.status == JoinRequestStatus.cancelled ||
          r.status == JoinRequestStatus.rejected ||
          (r.status == JoinRequestStatus.approved && r.meetup.cancelled))
      .toList();
}