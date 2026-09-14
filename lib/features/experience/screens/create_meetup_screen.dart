import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/experience_controller.dart';
import '../models/experience_model.dart';

// ===========================
// Location picker bottom sheet — its own StatefulWidget so it has a
// real `mounted` check. Prevents "setState() called after dispose()"
// if the user closes the sheet while a GPS/permission lookup or a
// search request is still in flight. Uses flutter_map (OpenStreetMap
// tiles) and Nominatim (OpenStreetMap's free geocoding search) — no
// API key or billing account required for either.
// ===========================
class _LocationPickerSheet extends StatefulWidget {
  final LatLng initialPosition;
  const _LocationPickerSheet({required this.initialPosition});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;
  _SearchResult({required this.displayName, required this.lat, required this.lon});
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng pickedPosition;
  final MapController mapController = MapController();
  bool locating = false;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  Timer? _debounce;
  bool searching = false;
  List<_SearchResult> searchResults = [];
  bool showResults = false;

  @override
  void initState() {
    super.initState();
    pickedPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        showResults = false;
      });
      return;
    }
    // Debounce so we're not firing a request on every keystroke.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      runSearch(query.trim());
    });
  }

  Future<void> runSearch(String query) async {
    setState(() {
      searching = true;
      showResults = true;
    });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&format=json&limit=6',
      );
      // NOTE: deliberately not setting a 'User-Agent' header — browsers
      // (Flutter Web) refuse to let JS set that header at all, so it
      // either gets silently stripped or can cause the request to be
      // treated inconsistently across browsers. Nominatim's CORS
      // config allows anonymous browser requests without it.
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          searchResults = data
              .map((item) => _SearchResult(
                    displayName: item['display_name'] as String,
                    lat: double.parse(item['lat'] as String),
                    lon: double.parse(item['lon'] as String),
                  ))
              .toList();
        });
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void selectSearchResult(_SearchResult result) {
    final newPos = LatLng(result.lat, result.lon);
    setState(() {
      pickedPosition = newPos;
      searchController.text = result.displayName;
      showResults = false;
      searchResults = [];
    });
    searchFocusNode.unfocus();
    mapController.move(newPos, 16);
  }

  Future<void> useCurrentLocation() async {
    setState(() => locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission finalPermission = permission;
      if (permission == LocationPermission.denied) {
        finalPermission = await Geolocator.requestPermission();
      }
      if (finalPermission == LocationPermission.denied ||
          finalPermission == LocationPermission.deniedForever) {
        if (!mounted) return;
        Get.snackbar("Location Permission Needed",
            "Please allow location access to use this feature");
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final newPos = LatLng(position.latitude, position.longitude);

      // The sheet may have been closed while we were awaiting the
      // permission prompt / GPS fix above — never touch state or the
      // map controller after that.
      if (!mounted) return;

      setState(() {
        pickedPosition = newPos;
      });
      mapController.move(newPos, mapController.camera.zoom);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar("Location Error", e.toString());
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "Set Meetup Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Search a place or tap on the map to drop a pin",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // ===== Search box =====
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search for a place or address",
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  searchController.clear();
                                  searchResults = [];
                                  showResults = false;
                                });
                              },
                            )
                          : null),
                ),
              ),
            ),

            if (showResults)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: searchResults.isEmpty && !searching
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "No results found",
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final r = searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                size: 18, color: AppColors.primary),
                            title: Text(
                              r.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () => selectSearchResult(r),
                          );
                        },
                      ),
              ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: widget.initialPosition,
                    initialZoom: 14,
                    onTap: (tapPosition, point) {
                      setState(() {
                        pickedPosition = point;
                        showResults = false;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.weekendmasti.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickedPosition,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: locating ? null : useCurrentLocation,
              icon: locating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primary),
              label: const Text("Use Current Location"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'lat': pickedPosition.latitude,
                  'lng': pickedPosition.longitude,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final controller = Get.find<ExperienceController>();

  final titleController = TextEditingController();
  final categoryController = TextEditingController(text: "Adventure");
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final seatsController = TextEditingController();
  final cityController = TextEditingController();
  final cityFocusNode = FocusNode();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  bool isPrivate = false;
  bool showCitySuggestions = false;

  Uint8List? bannerBytes;
  bool saving = false;

  double? selectedLat;
  double? selectedLng;

  // True while we're reverse-geocoding the picked lat/lng into a city
  // name. Drives the small spinner in the city field so it's obvious
  // the field is being auto-filled rather than sitting blank.
  bool resolvingCity = false;

  // Same idea for the location field — true while we're turning the
  // raw lat/lng into a readable address.
  bool resolvingAddress = false;

  final List<String> categoryOptions = const [
    "Adventure",
    "Coffee",
    "Cricket",
    "Music",
    "Cycling",
    "Food",
  ];

  // Starting suggestion set for the city autocomplete — the field
  // itself accepts any typed value, this list just powers the
  // suggestion dropdown as the user types. Still here as a manual
  // fallback/override for whenever reverse geocoding can't resolve a
  // city (offline, remote pin, rate-limited, etc).
  final List<String> cityOptions = const [
    "Hyderabad",
    "Chennai",
    "Bangalore",
    "Mumbai",
    "Delhi",
    "Pune",
    "Kolkata",
    "Ahmedabad",
    "Jaipur",
    "Lucknow",
    "Chandigarh",
    "Kochi",
    "Coimbatore",
    "Indore",
    "Surat",
    "Nagpur",
    "Visakhapatnam",
    "Bhopal",
    "Patna",
    "Vadodara",
    "Nashik",
    "Mysore",
    "Thiruvananthapuram",
    "Guwahati",
  ];

  // Suggestions filtered live against whatever the user has typed so
  // far in the city field.
  List<String> get filteredCityOptions {
    final query = cityController.text.trim().toLowerCase();
    if (query.isEmpty) return cityOptions;
    return cityOptions
        .where((c) => c.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Suggestions only ever show while the field is focused AND has
    // text in it — never on load, never after tapping away.
    cityFocusNode.addListener(() {
      setState(() {
        showCitySuggestions =
            cityFocusNode.hasFocus && cityController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    priceController.dispose();
    seatsController.dispose();
    cityController.dispose();
    cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        bannerBytes = bytes;
      });
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedEndTime = picked;
      });
    }
  }

  // ===========================
  // Reverse geocoding — turns the lat/lng the user picked on the map
  // into (a) a city name and (b) a short human-readable address, so
  // neither field is left showing raw coordinates. Uses the same
  // free Nominatim service as the location search (no API key or
  // billing needed). One request covers both fields since they come
  // from the same "address" breakdown Nominatim returns.
  //
  // FIX: this previously (1) sent a 'User-Agent' header, which
  // browsers refuse to let JS set at all — Flutter Web builds could
  // have this silently dropped or the whole request treated
  // inconsistently, causing reverse geocoding to fail more often than
  // it should; and (2) fell back to `null` for the address whenever
  // Nominatim's address breakdown didn't include road/neighbourhood/
  // suburb/state, even when Nominatim DID successfully resolve the
  // point and returned a perfectly good `display_name` — so the
  // location field was left showing raw "lat, lng" far more often
  // than necessary. Both fixed below: no more User-Agent header, and
  // `display_name` is now used as the fallback any time the short
  // address can't be built, so raw coordinates only ever show if the
  // network call itself genuinely fails.
  // ===========================
  Future<Map<String, String?>> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&zoom=18&addressdetails=1',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      final fullDisplayName = data['display_name'] as String?;

      if (address == null) {
        // Nominatim still resolved the point even if it couldn't break
        // it into components — show that instead of raw coordinates.
        return {'city': null, 'displayName': fullDisplayName};
      }

      // Nominatim doesn't tag every place the same way — a big metro
      // area comes back as "city", a smaller town as "town", etc.
      // Fall through the likely fields in order of specificity.
      final cityRaw = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'] ??
          address['state_district'] ??
          address['state'];
      final city =
          (cityRaw is String && cityRaw.trim().isNotEmpty) ? cityRaw.trim() : null;

      final shortAddress = _buildShortAddress(address, fallbackCity: city);

      return {
        'city': city,
        // Falls back to Nominatim's own full display_name — still a
        // real, readable place description — rather than leaving this
        // null and forcing the caller to keep showing coordinates.
        'displayName': shortAddress ?? fullDisplayName,
      };
    } catch (_) {
      return {};
    }
  }

  // Builds a short, readable address like "MG Road, Chennai, Tamil
  // Nadu" instead of Nominatim's full display_name (which tends to
  // be a long comma-separated dump including postal code, country,
  // etc — too long to sit nicely in the location field). Returns null
  // if none of the expected pieces are present — callers should fall
  // back to the full display_name in that case, not to coordinates.
  String? _buildShortAddress(Map<String, dynamic> address, {String? fallbackCity}) {
    final parts = <String>[];

    final streetLevel =
        address['road'] ?? address['neighbourhood'] ?? address['suburb'];
    if (streetLevel is String && streetLevel.trim().isNotEmpty) {
      parts.add(streetLevel.trim());
    }

    if (fallbackCity != null && fallbackCity.trim().isNotEmpty) {
      parts.add(fallbackCity.trim());
    }

    final state = address['state'];
    if (state is String && state.trim().isNotEmpty) {
      parts.add(state.trim());
    }

    return parts.isEmpty ? null : parts.join(', ');
  }

  // ===========================
  // Normalizes a city string to a consistent "Title Case" format
  // (e.g. "chennai", "CHENNAI", " Chennai " all become "Chennai").
  // The website's city filter does an exact string match against
  // whatever is saved here, so without this, meetups in the same
  // city but typed with different casing/spacing would be treated
  // as different cities and silently split the filter.
  // ===========================
  String normalizeCityName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // ===========================
  // Location picker (bottom sheet) — hosts _LocationPickerSheet, its
  // own StatefulWidget, so async GPS/permission/search calls can't
  // crash after the sheet is closed.
  // ===========================
  Future<void> pickLocation() async {
    LatLng initialPosition = const LatLng(17.3850, 78.4867); // Hyderabad default
    if (selectedLat != null && selectedLng != null) {
      initialPosition = LatLng(selectedLat!, selectedLng!);
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(initialPosition: initialPosition),
    );

    if (result == null) return;

    final lat = result['lat'] as double;
    final lng = result['lng'] as double;

    if (!mounted) return;
    setState(() {
      selectedLat = lat;
      selectedLng = lng;
      // Show the coordinates immediately as a placeholder — swapped
      // for a readable address below once reverse geocoding resolves.
      // If it genuinely fails, the coordinates stay as the last-resort
      // fallback and we tell the user to type it in by hand.
      locationController.text = "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
      resolvingCity = true;
      resolvingAddress = true;
    });

    final geo = await reverseGeocode(lat, lng);

    if (!mounted) return;
    setState(() {
      resolvingCity = false;
      resolvingAddress = false;
      if (geo['city'] != null) {
        cityController.text = normalizeCityName(geo['city']!);
      }
      if (geo['displayName'] != null) {
        locationController.text = geo['displayName']!;
      }
    });

    // Only reachable if reverseGeocode() genuinely failed (network
    // error, timeout, or Nominatim returned nothing usable at all) —
    // the coordinate fallback text is still sitting in the field, so
    // let the user know they should type the place name themselves.
    if (geo['displayName'] == null) {
      Get.snackbar(
        "Couldn't Detect Address",
        "Please type the location and city in manually.",
      );
    }
  }

  bool validate() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar("Missing Title", "Please enter a meetup title");
      return false;
    }
    if (categoryController.text.trim().isEmpty) {
      Get.snackbar("Missing Category", "Please enter a category");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      Get.snackbar("Missing Location", "Please set a location");
      return false;
    }
    if (cityController.text.trim().isEmpty) {
      Get.snackbar("Missing City",
          "Couldn't detect a city for this location — please type it in");
      return false;
    }
    if (selectedDate == null) {
      Get.snackbar("Missing Date", "Please select a date");
      return false;
    }
    if (selectedTime == null) {
      Get.snackbar("Missing Time", "Please select a start time");
      return false;
    }
    if (selectedEndTime == null) {
      Get.snackbar("Missing End Time", "Please select an end time");
      return false;
    }
    if (priceController.text.trim().isEmpty ||
        double.tryParse(priceController.text.trim()) == null) {
      Get.snackbar("Invalid Price", "Please enter a valid price (0 for free)");
      return false;
    }
    if (seatsController.text.trim().isEmpty ||
        int.tryParse(seatsController.text.trim()) == null) {
      Get.snackbar("Invalid Seats", "Please enter a valid number of seats");
      return false;
    }
    return true;
  }

  Future<void> submit() async {
    if (!validate()) return;

    setState(() {
      saving = true;
    });

    final combinedDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final combinedEndDate = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedEndTime!.hour,
      selectedEndTime!.minute,
    );

    if (!combinedEndDate.isAfter(combinedDate)) {
      Get.snackbar("Invalid End Time", "End time must be after the start time");
      setState(() {
        saving = false;
      });
      return;
    }

    // FIX: creator identity was never being recorded. createdBy stayed
    // at its default '' and organizerName stayed at its default "You"
    // for every meetup, no matter who actually created it — which is
    // what made the details screen unable to tell owners from everyone
    // else. Both are now pulled from the logged-in Firebase user.
    final currentUser = FirebaseAuth.instance.currentUser;
    final String creatorUid = currentUser?.uid ?? '';
    final String creatorName = (currentUser?.displayName?.trim().isNotEmpty ?? false)
        ? currentUser!.displayName!.trim()
        : (currentUser?.phoneNumber ?? 'Organizer');

    final newExperience = Experience(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      category: categoryController.text.trim(),
      location: locationController.text.trim(),
      city: normalizeCityName(cityController.text.trim()),
      image: "assets/experiences/trek.webp", // placeholder until real upload wired
      date: combinedDate,
      endDate: combinedEndDate,
      price: double.parse(priceController.text.trim()),
      joined: 0,
      seats: int.parse(seatsController.text.trim()),
      foodAvailable: false,
      description: descriptionController.text.trim(),
      organizerName: creatorName,
      isPrivate: isPrivate,
      participants: const [],
      gallery: const [],
      createdBy: creatorUid,
      latitude: selectedLat ?? 0.0,
      longitude: selectedLng ?? 0.0,
    );

    try {
      debugPrint("[CreateMeetup] submit() started");

      await controller.addExperience(newExperience).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              "Timed out after 15s — check internet connection and Firestore security rules.");
        },
      );

      debugPrint("[CreateMeetup] addExperience() succeeded");

      setState(() {
        saving = false;
      });

      Get.offNamed(AppRoutes.myMeetups);
      Get.snackbar(
        "Meetup Created",
        "\"${newExperience.title}\" is now live",
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      debugPrint("[CreateMeetup] FAILED: $e");
      debugPrint("[CreateMeetup] StackTrace: $stackTrace");

      setState(() {
        saving = false;
      });
      Get.snackbar(
        "Failed to Create Meetup",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    }
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Create Meetup",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickBanner,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  image: bannerBytes != null
                      ? DecorationImage(
                          image: MemoryImage(bannerBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: bannerBytes == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              "Add Banner Image",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            radius: 16,
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),

            fieldLabel("MEETUP TITLE"),
            TextField(
              controller: titleController,
              decoration: fieldDecoration("e.g. Sunday Coffee Meetup"),
            ),

            fieldLabel("CATEGORY"),
            TextField(
              controller: categoryController,
              onChanged: (_) => setState(() {}),
              decoration: fieldDecoration("e.g. Adventure, Coffee, Trekking..."),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryOptions.map((c) {
                final bool isSelected =
                    categoryController.text.trim().toLowerCase() == c.toLowerCase();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      categoryController.text = c;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            fieldLabel("DESCRIPTION"),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: fieldDecoration("What's this meetup about?"),
            ),

            fieldLabel("LOCATION"),
            GestureDetector(
              onTap: pickLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        locationController.text.isEmpty
                            ? "Set location on map"
                            : locationController.text,
                        style: TextStyle(
                          color: locationController.text.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (resolvingAddress)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            fieldLabel("CITY"),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auto-filled from the location you pick above. Still
                // editable by hand as a fallback for when reverse
                // geocoding can't resolve a city for the pin.
                TextField(
                  controller: cityController,
                  focusNode: cityFocusNode,
                  onChanged: (value) {
                    setState(() {
                      showCitySuggestions = value.trim().isNotEmpty;
                    });
                  },
                  decoration: fieldDecoration(
                    "Auto-filled after you set a location",
                  ).copyWith(
                    suffixIcon: resolvingCity
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                if (showCitySuggestions && filteredCityOptions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filteredCityOptions.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final c = filteredCityOptions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              size: 18, color: AppColors.primary),
                          title: Text(c, style: const TextStyle(fontSize: 14)),
                          onTap: () {
                            setState(() {
                              cityController.text = c;
                              showCitySuggestions = false;
                            });
                            cityFocusNode.unfocus();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),

            fieldLabel("DATE & TIME"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? "Select date"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            selectedTime == null
                                ? "Start time"
                                : selectedTime!.format(context),
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: pickEndTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            selectedEndTime == null
                                ? "End time"
                                : selectedEndTime!.format(context),
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            fieldLabel("PRICE (₹, 0 for free)"),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration("0"),
            ),

            fieldLabel("TOTAL SEATS"),
            TextField(
              controller: seatsController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration("e.g. 20"),
            ),

            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                "Private Meetup",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isPrivate
                    ? "Only people with the invite code/QR can join"
                    : "Anyone nearby can find and join",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: isPrivate,
              onChanged: (value) {
                setState(() {
                  isPrivate = value;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Create Meetup",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
