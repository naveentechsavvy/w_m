import 'package:cloud_firestore/cloud_firestore.dart';

class Experience {
  final String id;
  final String title;
  final String category;
  final String location;
  final String image;
  final DateTime date;
  final DateTime? endDate;
  final double price;
  final int joined;
  final int seats;
  final bool foodAvailable;

  final String description;
  final String organizerName;
  final bool isPrivate;
  final List<String> participants;
  final List<String> gallery;
  final String createdBy;

  final double latitude;
  final double longitude;

  final double avgRating;
  final int reviewCount;

  /// Soft-delete flag. Set true when the organizer cancels the
  /// meetup — the document is kept (not deleted) so it can still be
  /// shown in "Cancelled" lists on both the app and the website.
  final bool cancelled;

  /// Why the organizer cancelled, if they did. Null for meetups that
  /// were never cancelled.
  final String? cancelReason;

  Experience({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.image,
    required this.date,
    this.endDate,
    required this.price,
    required this.joined,
    required this.seats,
    required this.foodAvailable,
    this.description = "",
    this.organizerName = "You",
    this.isPrivate = false,
    this.participants = const [],
    this.gallery = const [],
    this.createdBy = "",
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.cancelled = false,
    this.cancelReason,
  });

  /// Falls back to a 2-hour default duration for older meetups that
  /// were created before `endDate` existed, so nothing crashes or
  /// shows "completed" prematurely just because the field is missing.
  DateTime get effectiveEndDate =>
      endDate ?? date.add(const Duration(hours: 2));

  /// Same status logic the website mirrors: cancelled wins over
  /// everything; otherwise "ongoing" if happening right now (between
  /// start and end time), "upcoming" if it hasn't started yet,
  /// "completed" if the end time has passed.
  String get computedStatus {
    if (cancelled) return 'cancelled';
    final now = DateTime.now();
    if (now.isBefore(date)) return 'upcoming';
    if (now.isAfter(effectiveEndDate)) return 'completed';
    return 'ongoing';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'location': location,
      'image': image,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'price': price,
      'joined': joined,
      'seats': seats,
      'foodAvailable': foodAvailable,
      'description': description,
      'organizerName': organizerName,
      'isPrivate': isPrivate,
      'participants': participants,
      'gallery': gallery,
      'createdBy': createdBy,
      'latitude': latitude,
      'longitude': longitude,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'cancelled': cancelled,
      'cancelReason': cancelReason,
    };
  }

  factory Experience.fromMap(String id, Map<String, dynamic> map) {
    return Experience(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      image: map['image'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      price: (map['price'] ?? 0).toDouble(),
      joined: map['joined'] ?? 0,
      seats: map['seats'] ?? 0,
      foodAvailable: map['foodAvailable'] ?? false,
      description: map['description'] ?? '',
      organizerName: map['organizerName'] ?? 'You',
      isPrivate: map['isPrivate'] ?? false,
      participants: List<String>.from(map['participants'] ?? []),
      gallery: List<String>.from(map['gallery'] ?? []),
      createdBy: map['createdBy'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      cancelled: map['cancelled'] ?? false,
      cancelReason: map['cancelReason'] as String?,
    );
  }

  factory Experience.fromDoc(DocumentSnapshot doc) {
    return Experience.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}