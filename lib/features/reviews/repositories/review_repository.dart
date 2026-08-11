import 'dart:typed_data';

import '../datasources/review_datasource.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final ReviewDataSource datasource = ReviewDataSource();

  Future<List<Review>> getReviewsForMeetup(String meetupId) =>
      datasource.getReviewsForMeetup(meetupId);

  Future<bool> hasUserReviewed(String meetupId, String userId) =>
      datasource.hasUserReviewed(meetupId, userId);

  Future<List<String>> uploadPhotos(
    String meetupId,
    String userId,
    List<Uint8List> photos,
  ) =>
      datasource.uploadPhotos(meetupId, userId, photos);

  Future<void> submitReview(Review review) => datasource.submitReview(review);
}