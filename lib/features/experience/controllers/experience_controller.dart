import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/experience_model.dart';
import '../repositories/experience_repository.dart';
import 'my_meetups_controller.dart';

class ExperienceController extends GetxController {
  final ExperienceRepository repository = ExperienceRepository();

  RxList<Experience> experiences = <Experience>[].obs;
  RxString selectedCategory = "All".obs;
  RxInt selectedNavIndex = 0.obs;
  RxBool isLoading = false.obs;
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
    loadMeetups();
  }

  Future<void> loadMeetups() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllMeetups();
      experiences.assignAll(result);
    } finally {
      isLoading.value = false;
    }
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
  // Create Meetup — writes to Firestore, then refreshes My Meetups
  // ===========================
  Future<void> addExperience(Experience newExperience) async {
    debugPrint("[ExperienceController] addExperience() start");

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint("[ExperienceController] ERROR: no user is logged in");
      throw Exception("You must be logged in to create a meetup.");
    }
    final uid = currentUser.uid;
    debugPrint("[ExperienceController] uid=$uid");

    final withCreator = Experience(
      id: newExperience.id,
      title: newExperience.title,
      category: newExperience.category,
      location: newExperience.location,
      image: newExperience.image,
      date: newExperience.date,
      price: newExperience.price,
      joined: newExperience.joined,
      seats: newExperience.seats,
      foodAvailable: newExperience.foodAvailable,
      description: newExperience.description,
      organizerName: newExperience.organizerName,
      isPrivate: newExperience.isPrivate,
      participants: newExperience.participants,
      gallery: newExperience.gallery,
      createdBy: uid,
    );

    debugPrint("[ExperienceController] calling repository.createMeetup()...");
    final newId = await repository.createMeetup(withCreator);
    debugPrint("[ExperienceController] createMeetup() returned id=$newId");

    experiences.insert(0, Experience.fromMap(newId, withCreator.toMap()));

    // Force My Meetups to refresh if it's already loaded in memory,
    // since its onInit() only runs once and won't pick this up otherwise.
    if (Get.isRegistered<MyMeetupsController>()) {
      debugPrint(
          "[ExperienceController] MyMeetupsController is registered, refreshing...");
      await Get.find<MyMeetupsController>().loadCreatedMeetups();
      debugPrint("[ExperienceController] loadCreatedMeetups() done");
    } else {
      debugPrint(
          "[ExperienceController] MyMeetupsController not registered yet, skipping refresh");
    }

    debugPrint("[ExperienceController] addExperience() complete");
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
