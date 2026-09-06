import 'dart:async';

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

  // Outgoing requests (mine) are cheap and don't need to be live — kept
  // as a plain snapshot, refreshed by loadAll().
  List<JoinRequest> _outgoing = [];

  // FIX: incoming requests (for meetups I organize) used to be fetched
  // once via a plain .get() in loadAll(), so a new request sent from
  // another device never appeared in this app until the screen was
  // manually reopened or pulled-to-refresh. Now it's a live Firestore
  // stream, so new requests appear in the Notifications feed
  // automatically, the same way friend requests already do.
  StreamSubscription<List<JoinRequest>>? _incomingSub;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    _incomingSub?.cancel();
    super.onClose();
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
      // Outgoing: requests I sent to join other people's meetups.
      _outgoing = await repository.getMyRequests();

      // Incoming: requests other people sent to join MY meetups —
      // now live via watchIncomingForMeetups instead of a one-time
      // fetch, so new requests show up without reopening the screen.
      final myMeetups = await experienceRepository.getMeetupsByCreator(uid);

      _incomingSub?.cancel();
      _incomingSub =
          repository.watchIncomingForMeetups(myMeetups).listen((incoming) {
        final merged = {
          for (final r in [..._outgoing, ...incoming]) r.id: r,
        };
        requests.assignAll(merged.values.toList());
      });
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
      // No need to call loadAll() here anymore for the incoming side —
      // the live stream will reflect the status change automatically.
      // Still refresh outgoing in case this device also has pending
      // requests of its own.
      _outgoing = await repository.getMyRequests();
    } catch (e) {
      Get.snackbar(
        "Couldn't approve",
        e is StateError ? e.message : "Something went wrong. Please try again.",
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Future<void> reject(String requestId) async {
    await repository.reject(requestId);
    _outgoing = await repository.getMyRequests();
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
    _outgoing = await repository.getMyRequests();
    // Re-merge immediately with whatever incoming data we currently
    // have, so "Request Pending" shows right away on the requester's
    // own device without waiting for the next stream event.
    final merged = {
      for (final r in [..._outgoing, ...requests.where((r) => !r.isMine)])
        r.id: r,
    };
    requests.assignAll(merged.values.toList());
  }

  Future<void> cancel(String requestId) async {
    await repository.cancel(requestId);
    _outgoing = await repository.getMyRequests();
  }
}