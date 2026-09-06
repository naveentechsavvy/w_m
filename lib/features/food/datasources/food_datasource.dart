import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item_model.dart';

/// Deliberately queries with a single .where() and NO .orderBy() on a
/// different field — a combo that requires a Firestore composite index
/// (the same trap that broke chat earlier). Sorting by category/name
/// happens client-side in the controller instead, so this never needs
/// an index and can't silently fail the same way.
class FoodDataSource {
  final _items = FirebaseFirestore.instance.collection('foodItems');

  Stream<List<FoodItem>> streamAvailableItems() {
    return _items
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FoodItem.fromDoc(d)).toList());
  }
}
