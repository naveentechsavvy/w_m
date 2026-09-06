import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../experience/models/experience_model.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';

/// One instance per meetup — instantiated with `tag: meetupId` by the
/// screens that need it (Meetup Details, Reviews, Write Review), so
/// review state for one meetup never leaks into another.
class ReviewController extends GetxController {
  final String meetupId;
  ReviewController({required this.meetupId});

  final ReviewRepository repository = ReviewRepository();

  final RxList<Review> reviews = <Review>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;

  // Write Review form state
  RxDouble rating = 0.0.obs;
  final commentController = TextEditingController();
  final RxList<Uint8List> selectedPhotos = <Uint8List>[].obs;
  RxBool isSubmitting = false.obs;

  RxBool alreadyReviewed = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReviews();
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> loadReviews() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await repository.getReviewsForMeetup(meetupId);
      reviews.assignAll(result);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        alreadyReviewed.value = await repository.hasUserReviewed(meetupId, uid);
      }
    } catch (e) {
      // If this prints a Firestore error containing a URL like
      // ".../firestore/indexes?create_composite=...", open that link
      // and create the composite index it asks for (meetupId + createdAt).
      // Reviews are being written successfully; they just can't be
      // queried back until that index exists.
      debugPrint("[ReviewController] loadReviews failed: $e");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Eligibility: must have joined (is in participants) and the
  /// meetup date must be in the past, and no existing review yet.
  ///
  /// FIX: `alreadyReviewed.value` is now read unconditionally at the
  /// top of this method, before any early return. Previously it was
  /// only reached when `uid != null`, so when this method was called
  /// from inside an `Obx(() => ...)` while the user wasn't logged in
  /// (or auth hadn't finished initializing yet), the early `return
  /// false;` for the null-uid case meant NO observable was read
  /// during that build. GetX's `Obx` has nothing to subscribe to in
  /// that case and throws:
  /// "[Get] the improper use of a GetX has been detected."
  /// Reading the .obs value first guarantees Obx always registers a
  /// dependency, regardless of which branch runs afterward.
  bool canReview(Experience meetup) {
    final reviewed = alreadyReviewed.value; // always read first
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final isParticipant = meetup.participants.contains(uid);
    final isCompleted = meetup.date.isBefore(DateTime.now());
    return isParticipant && isCompleted && !reviewed;
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    selectedPhotos.add(bytes);
  }

  void removePhoto(int index) {
    selectedPhotos.removeAt(index);
  }

  Future<bool> submitReview() async {
    if (rating.value <= 0) {
      Get.snackbar("Rating Required", "Please select a star rating.");
      return false;
    }
    if (commentController.text.trim().isEmpty) {
      Get.snackbar("Comment Required", "Please write a short comment.");
      return false;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Get.snackbar("Error", "You must be logged in to submit a review.");
      return false;
    }

    isSubmitting.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString("full_name") ?? "User";
      final userPhotoUrl = prefs.getString("avatar_url");

      final photoUrls = selectedPhotos.isEmpty
          ? <String>[]
          : await repository.uploadPhotos(meetupId, uid, selectedPhotos);

      final review = Review(
        id: '',
        meetupId: meetupId,
        userId: uid,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating.value,
        comment: commentController.text.trim(),
        photos: photoUrls,
        createdAt: DateTime.now(),
      );

      // This write is what actually matters for "did the submission
      // succeed" — if it throws, we fall through to the catch below
      // and correctly report failure to the user.
      await repository.submitReview(review);
      alreadyReviewed.value = true;

      // The review is already saved at this point. A failure to
      // refresh the list (e.g. a missing Firestore composite index)
      // must never be reported to the user as a failed submission —
      // it's isolated in its own try/catch so it can't reach the
      // outer catch and flip a successful submit into "Submission Failed".
      try {
        await loadReviews();
      } catch (e) {
        debugPrint("[ReviewController] post-submit refresh failed: $e");
      }

      Get.snackbar("Review Submitted", "Thanks for sharing your experience!");
      return true;
    } catch (e) {
      debugPrint("[ReviewController] submitReview failed: $e");
      Get.snackbar("Submission Failed", "Something went wrong. Please try again.");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
