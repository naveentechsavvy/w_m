import '../datasources/food_datasource.dart';
import '../models/food_item_model.dart';

class FoodRepository {
  final FoodDataSource _datasource = FoodDataSource();

  Stream<List<FoodItem>> streamAvailableItems() =>
      _datasource.streamAvailableItems();
}
