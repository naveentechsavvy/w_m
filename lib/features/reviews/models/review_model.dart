import 'package:cloud_firestore/cloud_firestore.dart';

/// Backed by the existing Firestore `reviews` collection.
class Review {
  final String id;
  final String meetupId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating; // 1.0 - 5.0
  final String comment;
  final List<String> photos;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.meetupId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    this.photos = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetupId': meetupId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      meetupId: map['meetupId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Review.fromDoc(DocumentSnapshot doc) {
    return Review.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}