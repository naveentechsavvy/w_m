import 'package:get/get.dart';

import '../models/experience_model.dart';

class ExperienceController extends GetxController {

  RxList<Experience> experiences = <Experience>[].obs;

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
        category: "Networking",
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
        category: "Sports",
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

}