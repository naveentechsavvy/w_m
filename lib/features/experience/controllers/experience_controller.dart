import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../models/experience_model.dart';
import '../repositories/experience_repository.dart';
import 'my_meetups_controller.dart';

class ExperienceController extends GetxController {
  final ExperienceRepository repository = ExperienceRepository();
  final LocationService locationService = LocationService();

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

  // ===========================
  // Location state (for Nearby + Home greeting chip)
  // ===========================
  Rx<Position?> currentPosition = Rx<Position?>(null);
  RxString currentLocationLabel = "Set your location".obs;
  RxBool locationLoading = false.obs;

  /// Meetups within this radius count as "nearby". Adjust as needed.
  static const double _nearbyRadiusKm = 15.0;

  @override
  void onInit() {
    super.onInit();
    loadMeetups();
    refreshLocation();
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

  /// Fetches current GPS position + a readable label. Safe to call
  /// again any time the user taps "change location" — doesn't throw
  /// if permission is denied, it just leaves the old state in place.
  Future<void> refreshLocation() async {
    locationLoading.value = true;
    try {
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        currentLocationLabel.value = "Enable location";
        return;
      }
      currentPosition.value = position;

      final label = await locationService.getReadableAddress(
        position.latitude,
        position.longitude,
      );
      currentLocationLabel.value = label ?? "Current location";
    } finally {
      locationLoading.value = false;
    }
  }

  /// Distance in km from the user's current position to an experience.
  /// Returns null if we don't have a GPS fix yet.
  double? distanceToKm(Experience e) {
    final pos = currentPosition.value;
    if (pos == null) return null;
    return locationService.distanceInKm(
      pos.latitude,
      pos.longitude,
      e.latitude,
      e.longitude,
    );
  }

  // ===========================
  // Category filtering
  // ===========================
  void changeCategory(String category) {
    selectedCategory.value = category;
  }

  List<Experience> get _upcoming =>
      experiences.where((e) => e.date.isAfter(DateTime.now())).toList();

  List<Experience> get _filteredByCategory {
    final base = _upcoming;
    if (selectedCategory.value == "All") return base;
    return base.where((e) => e.category == selectedCategory.value).toList();
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
      latitude: newExperience.latitude,
      longitude: newExperience.longitude,
    );

    debugPrint("[ExperienceController] calling repository.createMeetup()...");
    final newId = await repository.createMeetup(withCreator);
    debugPrint("[ExperienceController] createMeetup() returned id=$newId");

    experiences.insert(0, Experience.fromMap(newId, withCreator.toMap()));

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

  /// GPS-based: meetups within `_nearbyRadiusKm`, sorted closest-first.
  /// Falls back to the full filtered list if we don't have a GPS fix
  /// yet (e.g. permission not granted), so the section isn't empty
  /// while location is loading.
  List<Experience> get nearby {
    final pos = currentPosition.value;
    if (pos == null) return _filteredByCategory;

    final withDistance = _filteredByCategory
        .map((e) => MapEntry(e, distanceToKm(e) ?? double.infinity))
        .where((entry) => entry.value <= _nearbyRadiusKm)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return withDistance.map((entry) => entry.key).toList();
  }

  List<Experience> get recommended =>
      _filteredByCategory.where((e) => e.foodAvailable == true).toList();
}