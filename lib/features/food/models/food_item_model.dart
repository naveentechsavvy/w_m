import 'package:cloud_firestore/cloud_firestore.dart';

/// Matches the exact schema written by the Angular admin panel's
/// FoodService (collection: 'foodItems'). Field names are kept
/// identical on purpose so both apps read/write the same shape
/// without any translation layer.
class FoodItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final bool isAvailable;
  final DateTime? createdAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory FoodItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? 'Other') as String,
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0).toDouble(),
      description: (data['description'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      isAvailable: (data['isAvailable'] ?? true) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
