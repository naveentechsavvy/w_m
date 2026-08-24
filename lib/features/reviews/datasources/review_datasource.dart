import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../experience/datasources/experience_datasource.dart';
import '../models/review_model.dart';

class ReviewDataSource {
  final _col = FirebaseFirestore.instance.collection('reviews');
  final ExperienceDataSource _experienceDataSource = ExperienceDataSource();

  Future<List<Review>> getReviewsForMeetup(String meetupId) async {
    final snap = await _col
        .where('meetupId', isEqualTo: meetupId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Review.fromDoc(d)).toList();
  }

  Future<bool> hasUserReviewed(String meetupId, String userId) async {
    final snap = await _col
        .where('meetupId', isEqualTo: meetupId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<List<String>> uploadPhotos(
    String meetupId,
    String userId,
    List<Uint8List> photos,
  ) async {
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final ref = FirebaseStorage.instance.ref().child(
          'review_photos/$meetupId/${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putData(photos[i], SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  /// Writes the review document. This is the operation that actually
  /// matters for "did the submission succeed" — everything after this
  /// (aggregate recalculation) is best-effort and must never cause a
  /// successfully-written review to be reported back to the user as a
  /// failed submission.
  Future<void> submitReview(Review review) async {
    final docRef = _col.doc();
    await docRef.set(review.toMap());

    // Aggregate recalculation is isolated in its own try/catch so a
    // permission error or missing index here (e.g. a reviewer not
    // having write access to the meetup doc's avgRating/reviewCount
    // fields under current Firestore rules) can never bubble up and
    // make submitReview() throw after the review was already saved.
    try {
      await _recalculateAggregate(review.meetupId);
    } catch (e) {
      debugPrint(
        "[ReviewDataSource] Aggregate recalculation failed (review was still saved): $e",
      );
    }
  }

  /// Recomputes avgRating/reviewCount for a meetup from its reviews and
  /// writes them onto the meetup doc, so Experience Card / Meetup Details
  /// can read them directly without querying all reviews each time.
  Future<void> _recalculateAggregate(String meetupId) async {
    final snap = await _col.where('meetupId', isEqualTo: meetupId).get();
    final count = snap.docs.length;
    final avg = count == 0
        ? 0.0
        : snap.docs
                .map((d) => (d.data()['rating'] ?? 0).toDouble())
                .reduce((a, b) => a + b) /
            count;

    await _experienceDataSource.meetupDocRef(meetupId).update({
      'avgRating': avg,
      'reviewCount': count,
    });
  }
}
