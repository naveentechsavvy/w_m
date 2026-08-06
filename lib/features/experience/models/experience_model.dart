import 'package:cloud_firestore/cloud_firestore.dart';

class Experience {
  final String id;
  final String title;
  final String category;
  final String location;
  final String image;
  final DateTime date;
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

  final double latitude;   // NEW
  final double longitude;  // NEW

  Experience({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.image,
    required this.date,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'location': location,
      'image': image,
      'date': Timestamp.fromDate(date),
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
    );
  }

  factory Experience.fromDoc(DocumentSnapshot doc) {
    return Experience.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}