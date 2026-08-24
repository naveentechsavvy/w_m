import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../models/experience_model.dart';
import '../repositories/experience_repository.dart';
import 'app_config_controller.dart';
import 'my_meetups_controller.dart';
import 'subscription_controller.dart';

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

    // Premium gating: controlled by the admin flag at
    // app_config/settings.premiumEnabled in Firestore.
    // - Flag OFF  -> anyone can create a meetup (free-for-all launch
    //                period), regardless of subscription status.
    // - Flag ON   -> only users with an active Premium subscription
    //                can create; everyone else is blocked here.
    final appConfigController = Get.isRegistered<AppConfigController>()
        ? Get.find<AppConfigController>()
        : Get.put(AppConfigController(), permanent: true);
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);

    if (appConfigController.premiumEnabled.value &&
        !subscriptionController.isPremium.value) {
      debugPrint(
          "[ExperienceController] blocked: premium is required and this user isn't subscribed");
      throw Exception(
          "Creating meetups is a Premium feature. Subscribe to Premium to create your own meetup.");
    }

    // One-active-group-at-a-time rule: an organizer can't create a new
    // meetup while they still have one that hasn't happened yet.
    // "Ended" means either the date/time has passed, or it was
    // cancelled — cancelMeetup() already hard-deletes the doc (see
    // ExperienceDataSource.deleteMeetup), so a cancelled meetup simply
    // won't appear in getMeetupsByCreator() anymore. That means the
    // only thing left to check here is whether any of the organizer's
    // remaining meetups still have a future date.
    final existingMeetups = await repository.getMeetupsByCreator(uid);
    final hasActiveMeetup =
        existingMeetups.any((e) => e.date.isAfter(DateTime.now()));
    if (hasActiveMeetup) {
      debugPrint(
          "[ExperienceController] blocked: organizer already has an active meetup");
      throw Exception(
          "You already have an active meetup. You can create a new one once it's completed or cancelled.");
    }

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
