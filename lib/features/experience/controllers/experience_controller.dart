import 'package:get/get.dart';

import '../models/experience_model.dart';

class ExperienceController extends GetxController {

  RxList<Experience> experiences = <Experience>[].obs;

  RxString selectedCategory = "All".obs;

  RxInt selectedNavIndex = 0.obs;

  RxList<String> categories = <String>[
    "All",
    "Adventure",
    "Coffee",
    "Cricket",
    "Music",
    "Cycling",
    "Food",
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadDummyData();
  }

  void loadDummyData() {

    experiences.assignAll([

      Experience(
        id: "1",
        title: "Sunday Sunrise Trek",
        category: "Adventure",
        location: "Hyderabad",
        image: "assets/experiences/trek.webp",
        date: DateTime.now(),
        price: 499,
        joined: 12,
        seats: 20,
        foodAvailable: true,
      ),

      Experience(
        id: "2",
        title: "Coffee Networking",
        category: "Coffee",
        location: "Banjara Hills",
        image: "assets/experiences/coffee.jpg",
        date: DateTime.now(),
        price: 199,
        joined: 18,
        seats: 25,
        foodAvailable: false,
      ),

      Experience(
        id: "3",
        title: "Weekend Cricket",
        category: "Cricket",
        location: "Gachibowli",
        image: "assets/experiences/cricket.jpg",
        date: DateTime.now(),
        price: 99,
        joined: 14,
        seats: 22,
        foodAvailable: true,
      ),

    ]);

  }

  // ===========================
  // Category filtering
  // ===========================

  void changeCategory(String category) {
    selectedCategory.value = category;
  }

  List<Experience> get _filteredByCategory {
    if (selectedCategory.value == "All") return experiences;
    return experiences
        .where((e) => e.category == selectedCategory.value)
        .toList();
  }

  // ===========================
  // Bottom navigation
  // ===========================

  void changeNavIndex(int index) {
    selectedNavIndex.value = index;
  }

  // ===========================
  // Section getters
  // ===========================

  List<Experience> get trending => _filteredByCategory;

  List<Experience> get nearby => _filteredByCategory
      .where((e) => e.location == "Hyderabad" || e.location == "Gachibowli")
      .toList();

  List<Experience> get recommended =>
      _filteredByCategory.where((e) => e.foodAvailable == true).toList();

}