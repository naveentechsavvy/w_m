import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/experience_model.dart';
import '../models/join_request_model.dart';
import '../repositories/experience_repository.dart';
import '../repositories/join_request_repository.dart';

/// Single source of truth for join requests across the app.
/// Backed by Firestore `join_requests` collection.
class JoinRequestsController extends GetxController {
  final JoinRequestRepository repository = JoinRequestRepository();
  final ExperienceRepository experienceRepository = ExperienceRepository();

  final RxList<JoinRequest> requests = <JoinRequest>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // No signed-in user — nothing to load. Avoids a crash if this
      // controller is ever constructed during a signed-out state
      // (e.g. a stale route hit right after logout).
      requests.clear();
      return;
    }

    isLoading.value = true;
    try {
      // Outgoing: requests I sent to join other people's meetups
      final outgoing = await repository.getMyRequests();

      // Incoming: requests other people sent to join MY meetups
      final myMeetups = await experienceRepository.getMeetupsByCreator(uid);
      final incoming = <JoinRequest>[];
      for (final m in myMeetups) {
        incoming.addAll(await repository.getRequestsForMeetup(m));
      }

      final merged = {for (var r in [...outgoing, ...incoming]) r.id: r};
      requests.assignAll(merged.values.toList());
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================
  // Incoming (organizer side)
  // ===========================
  List<JoinRequest> get pendingIncoming => requests
      .where((r) => !r.isMine && r.status == JoinRequestStatus.pending)
      .toList();

  List<JoinRequest> pendingIncomingForMeetup(String meetupId) => requests
      .where((r) =>
          !r.isMine &&
          r.status == JoinRequestStatus.pending &&
          r.meetup.id == meetupId)
      .toList();

  /// Approves a request. The datasource does this as a single atomic
  /// transaction (status flip + participants + joined count), and can
  /// throw a [StateError] — e.g. if the meetup filled up between the
  /// organizer opening the screen and tapping Approve. That error is
  /// caught here and surfaced via snackbar rather than left to crash
  /// the tap handler silently.
  Future<void> approve(String requestId) async {
    try {
      await repository.approve(requestId);
      await loadAll();
    } catch (e) {
      Get.snackbar(
        "Couldn't approve",
        e is StateError ? e.message : "Something went wrong. Please try again.",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      // Refresh anyway — another organizer/session may have changed
      // state (e.g. the meetup filled up), so the list should reflect
      // the current truth even though this approval failed.
      await loadAll();
    }
  }

  Future<void> reject(String requestId) async {
    await repository.reject(requestId);
    await loadAll();
  }

  // ===========================
  // Outgoing (participant side)
  // ===========================
  List<JoinRequest> get myRequests =>
      requests.where((r) => r.isMine).toList();

  bool hasRequested(String meetupId) => requests.any(
        (r) =>
            r.isMine &&
            r.meetup.id == meetupId &&
            r.status != JoinRequestStatus.cancelled &&
            r.status != JoinRequestStatus.rejected,
      );

  JoinRequest? myRequestFor(String meetupId) {
    try {
      return requests.firstWhere(
        (r) => r.isMine && r.meetup.id == meetupId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> sendRequest(Experience meetup) async {
    if (hasRequested(meetup.id)) return;
    await repository.sendRequest(meetup);
    await loadAll();
  }

  Future<void> cancel(String requestId) async {
    await repository.cancel(requestId);
    await loadAll();
  }
}
