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
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Eligibility: must have joined (is in participants) and the
  /// meetup date must be in the past, and no existing review yet.
  bool canReview(Experience meetup) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final isParticipant = meetup.participants.contains(uid);
    final isCompleted = meetup.date.isBefore(DateTime.now());
    return isParticipant && isCompleted && !alreadyReviewed.value;
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

      await repository.submitReview(review);
      alreadyReviewed.value = true;
      await loadReviews();

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