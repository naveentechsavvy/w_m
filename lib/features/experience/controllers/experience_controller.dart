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
  RxString selectedCity = "All".obs;
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
  static const double _nearbyRadiusKm = 20.0;

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

  // ===========================
  // City filtering
  // ===========================
  /// `city` can be an exact city name (from tapping a suggestion) or a
  /// partial, in-progress search string (typed live). Either way it's
  /// stored as-is and matched as a case-insensitive substring in
  /// `filteredExperiences` below — "All" (or empty) means no filter.
  void changeCity(String city) {
    selectedCity.value = city;
  }

  /// Built from whatever cities actually exist across current meetups
  /// (already normalized to consistent Title Case at creation time —
  /// see normalizeCityName() in CreateMeetupScreen), so this list
  /// never goes stale or needs manual updates as new cities show up.
  /// "All" always sits first regardless of alphabetical order.
  List<String> get cities {
    final unique = experiences
        .map((e) => e.city.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ["All", ...unique];
  }

  // FIX: this feeds Trending/Nearby/Recommended on Explore — public
  // listings anyone can browse and join. It previously only checked
  // `date.isAfter(now)`, so a meetup that had already started (i.e.
  // currently "Ongoing", not "Upcoming") would incorrectly disappear
  // from the app even though it was still active and joinable — the
  // web admin's "All"/"Ongoing" tabs still showed it fine because
  // they don't apply this same has-it-started filter. We now check
  // `effectiveEndDate` instead of `date`, so a meetup stays visible
  // for its entire active window (from creation until it actually
  // ends), not just until its start time. Cancelled meetups are still
  // excluded outright, since Explore should never surface something
  // the organizer called off — regardless of whether anyone had
  // joined it.
  List<Experience> get _upcoming => experiences
      .where((e) => !e.cancelled && e.effectiveEndDate.isAfter(DateTime.now()))
      .toList();

  List<Experience> get _filteredByCategory {
    final base = _upcoming;
    if (selectedCategory.value == "All") return base;
    return base.where((e) => e.category == selectedCategory.value).toList();
  }

  /// Category + city combined — the single list Explore now shows.
  /// City matching is a case-insensitive substring match (e.g. typing
  /// "che" matches "Chennai"), not an exact match, so results update
  /// live as the user types rather than only after picking a
  /// suggestion.
  List<Experience> get filteredExperiences {
    final base = _filteredByCategory;
    final query = selectedCity.value.trim();
    if (query.isEmpty || query == "All") return base;

    final lowerQuery = query.toLowerCase();
    return base
        .where((e) => e.city.toLowerCase().contains(lowerQuery))
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

    final existingMeetups = await repository.getMeetupsByCreator(uid);
    final hasActiveMeetup = existingMeetups.any(
      (e) => !e.cancelled && e.effectiveEndDate.isAfter(DateTime.now()),
    );
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
      city: newExperience.city,
      image: newExperience.image,
      date: newExperience.date,
      endDate: newExperience.endDate,
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