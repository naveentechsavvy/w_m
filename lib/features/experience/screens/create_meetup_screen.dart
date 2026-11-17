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
// Nominatim usage policy requires a real User-Agent identifying the
// app; requests without one are frequently blocked/rejected, which is
// why search + reverse geocoding were silently failing before. Put a
// real contact/app identifier here.
// ===========================
const Map<String, String> _nominatimHeaders = {
  'User-Agent': 'WeekendMasti/1.0 (contact@weekendmasti.com)',
};
 
// Hyderabad — used ONLY as a last-resort fallback if GPS is truly
// unavailable (services off, permission denied, or lookup fails).
const LatLng _fallbackLocation = LatLng(17.3850, 78.4867);
 
/// Attempts to get the device's real current position for use as the
/// initial map center. Falls back to [_fallbackLocation] only if
/// location services/permissions are unavailable or the lookup fails.
Future<LatLng> _getBestGuessLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _fallbackLocation;
 
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fallbackLocation;
    }
 
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } catch (_) {
    return _fallbackLocation;
  }
}
 
// ===========================
// Location picker bottom sheet — its own StatefulWidget so it has a
// real `mounted` check. Prevents "setState() called after dispose()"
// if the user closes the sheet while a GPS/permission lookup or a
// search request is still in flight. Uses flutter_map (OpenStreetMap
// tiles) and Nominatim (OpenStreetMap's free geocoding search) — no
// API key or billing account required for either.
// ===========================
class _LocationPickerSheet extends StatefulWidget {
  /// Previously picked point, or null on first open — then the map starts
  /// at the fallback and moves to the user's location once GPS answers.
  final LatLng? initialPosition;
  const _LocationPickerSheet({this.initialPosition});
 
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
 
  late final LatLng _startPosition;

  /// True once the user has tapped the map or chosen a search result,
  /// so a late GPS answer doesn't move their pin.
  bool _userPicked = false;

  @override
  void initState() {
    super.initState();
    _startPosition = widget.initialPosition ?? _fallbackLocation;
    pickedPosition = _startPosition;
    // Find the current location in the background — the map is
    // already visible meanwhile.
    if (widget.initialPosition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locateOnOpen());
    }
  }

  Future<void> _locateOnOpen() async {
    if (!mounted) return;
    setState(() => locating = true);
    try {
      final pos = await _getBestGuessLocation();
      if (!mounted || _userPicked || pos == _fallbackLocation) return;
      setState(() => pickedPosition = pos);
      try {
        mapController.move(pos, 15);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => locating = false);
    }
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
        '&format=json&limit=6'
        '&countrycodes=in', // bias results toward India; drop this if you want global search
      );
      final response = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 10));
 
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
        debugPrint(
            '[LocationSearch] Nominatim returned ${response.statusCode}: ${response.body}');
        setState(() => searchResults = []);
      }
    } catch (e) {
      debugPrint('[LocationSearch] search failed: $e');
      if (!mounted) return;
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }
 
  void selectSearchResult(_SearchResult result) {
    final newPos = LatLng(result.lat, result.lon);
    setState(() {
      _userPicked = true;
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        Get.snackbar("Location Services Off",
            "Please turn on GPS/location services and try again");
        return;
      }
 
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
 
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final newPos = LatLng(position.latitude, position.longitude);
 
      if (!mounted) return;
 
      setState(() {
        pickedPosition = newPos;
      });
      mapController.move(newPos, 16);
    } catch (e) {
      debugPrint('[LocationPicker] useCurrentLocation failed: $e');
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
        // Extra bottom space = phone's navigation bar height, so the
        // Confirm Location button is never hidden behind it.
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
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
            // Back arrow (same icon as app bars) — closes without picking,
            // so nothing on Create Meetup changes.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const BackButtonIcon(),
                  color: AppColors.textPrimary,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    "Set Meetup Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Search a place or tap on the map to drop a pin",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
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
            Stack(
              children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _startPosition,
                    initialZoom: 14,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _userPicked = true;
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
                // Small spinner while the current location is being found.
                if (locating)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
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
 
  bool resolvingCity = false;
  bool resolvingAddress = false;
 
  final List<String> categoryOptions = const [
    "Adventure",
    "Coffee",
    "Cricket",
    "Music",
    "Cycling",
    "Food",
  ];
 
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
  // Category picker (bottom sheet) — grid of small cards, 3 per row.
  // The app has no category icons, so each card shows only the name.
  // Selected card: primary border + light primary tint.
  // ===========================
  Future<void> pickCategory() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final media = MediaQuery.of(context);
        final current = categoryController.text.trim().toLowerCase();
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Container(
            // Bottom safe-area so the last row isn't under the nav bar.
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + media.viewPadding.bottom),
            constraints: BoxConstraints(maxHeight: media.size.height * 0.75),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Scrolls inside the sheet if the list grows.
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: categoryOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 52,
                    ),
                    itemBuilder: (context, index) {
                      final c = categoryOptions[index];
                      final isSelected = current == c.toLowerCase();
                      return Material(
                        color: isSelected ? AppColors.primaryTint : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_fieldRadius),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  c,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
 
    if (selected != null) {
      setState(() {
        categoryController.text = selected;
      });
    }
  }
 
  Future<Map<String, String?>> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&zoom=18&addressdetails=1',
      );
      final response = await http
          .get(uri, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 10));
 
      if (response.statusCode != 200) {
        debugPrint(
            '[ReverseGeocode] Nominatim returned ${response.statusCode}: ${response.body}');
        return {};
      }
 
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      final fullDisplayName = data['display_name'] as String?;
 
      if (address == null) {
        return {'city': null, 'displayName': fullDisplayName};
      }
 
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
        'displayName': shortAddress ?? fullDisplayName,
      };
    } catch (e) {
      debugPrint('[ReverseGeocode] failed: $e');
      return {};
    }
  }
 
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
 
  bool _openingLocationPicker = false;

  Future<void> pickLocation() async {
    // Ignore double taps while the picker is open.
    if (_openingLocationPicker) return;
    _openingLocationPicker = true;

    // Open straight away. Previously this waited for GPS (permission +
    // up to 10s fix) BEFORE opening, which made it slow. Now the sheet
    // finds the current location itself while the map is showing.
    final LatLng? initialPosition = (selectedLat != null && selectedLng != null)
        ? LatLng(selectedLat!, selectedLng!)
        : null;

    Map<String, dynamic>? result;
    try {
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _LocationPickerSheet(initialPosition: initialPosition),
      );
    } finally {
      _openingLocationPicker = false;
    }

    // Back / swipe down without confirming: keep everything as it was.
    if (result == null) return;
 
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
 
    if (!mounted) return;
    setState(() {
      selectedLat = lat;
      selectedLng = lng;
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
      image: "assets/experiences/trek.webp",
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
 
  // ---- Shared field look (UI only) ----
  // Every field — typed or tap-to-pick — uses the same white box, soft
  // border, 14 radius, ~54 height and 16px inner padding.
  static const double _fieldRadius = 14;
  static const double _fieldHeight = 54;
  static const double _fieldIconSize = 20;
  static const Color _readOnlyFill = Color(0xFFF4F1EC);

  OutlineInputBorder _fieldBorder([Color color = AppColors.divider, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: _fieldBorder(),
      enabledBorder: _fieldBorder(),
      focusedBorder: _fieldBorder(AppColors.primary, 1.4),
    );
  }

  /// City is auto-filled from the map, so it looks read-only: tinted
  /// background, no focus highlight, muted hint. It can still be typed
  /// in when the city couldn't be detected (same as before).
  InputDecoration cityDecoration(String hint) {
    return fieldDecoration(hint).copyWith(
      fillColor: _readOnlyFill,
      enabledBorder: _fieldBorder(_readOnlyFill),
      focusedBorder: _fieldBorder(_readOnlyFill),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    );
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_fieldRadius),
        border: Border.all(color: AppColors.divider),
      );

  /// Tap-to-pick field (Category, Location, Date, Start, End) styled to
  /// match the text fields.
  Widget tapField({
    required IconData icon,
    required String text,
    required bool isEmpty,
    required VoidCallback onTap,
    List<Widget> trailing = const [],
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: _fieldHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _boxDecoration,
        child: Row(
          children: [
            Icon(icon, size: _fieldIconSize, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
        // Same back arrow and same behaviour (pop the screen), just with
        // a 44x44 tap area, vertically centred with the title.
        leading: Center(
          child: IconButton(
            icon: const BackButtonIcon(),
            color: AppColors.textPrimary,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      // SafeArea keeps the Create button above the phone's navigation bar.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  border: Border.all(color: AppColors.divider),
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
 
            fieldLabel("Meetup title"),
            TextField(
              controller: titleController,
              decoration: fieldDecoration("e.g. Sunday Coffee Meetup"),
            ),

            fieldLabel("Category"),
            tapField(
              icon: Icons.category_outlined,
              text: categoryController.text.isEmpty
                  ? "Select a category"
                  : categoryController.text,
              isEmpty: categoryController.text.isEmpty,
              onTap: pickCategory,
              trailing: const [
                Icon(Icons.chevron_right,
                    size: _fieldIconSize, color: AppColors.textSecondary),
              ],
            ),

            fieldLabel("Description"),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: fieldDecoration("What's this meetup about?"),
            ),

            fieldLabel("Location"),
            tapField(
              icon: Icons.location_on_outlined,
              text: locationController.text.isEmpty
                  ? "Set location on map"
                  : locationController.text,
              isEmpty: locationController.text.isEmpty,
              onTap: pickLocation,
              trailing: [
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
                    size: _fieldIconSize, color: AppColors.textSecondary),
              ],
            ),

            fieldLabel("City"),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: cityController,
                  focusNode: cityFocusNode,
                  onChanged: (value) {
                    setState(() {
                      showCitySuggestions = value.trim().isNotEmpty;
                    });
                  },
                  decoration: cityDecoration(
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
                      borderRadius: BorderRadius.circular(_fieldRadius),
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

            fieldLabel("Date & time"),
            tapField(
              icon: Icons.calendar_today_outlined,
              text: selectedDate == null
                  ? "Select date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              isEmpty: selectedDate == null,
              onTap: pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: tapField(
                    icon: Icons.access_time,
                    text: selectedTime == null
                        ? "Start time"
                        : selectedTime!.format(context),
                    isEmpty: selectedTime == null,
                    onTap: pickTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: tapField(
                    icon: Icons.access_time,
                    text: selectedEndTime == null
                        ? "End time"
                        : selectedEndTime!.format(context),
                    isEmpty: selectedEndTime == null,
                    onTap: pickEndTime,
                  ),
                ),
              ],
            ),

            fieldLabel("Price (₹, 0 for free)"),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration("0"),
            ),

            fieldLabel("Total seats"),
            TextField(
              controller: seatsController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration("e.g. 20"),
            ),

            const SizedBox(height: 20),

            // Private Meetup — same white card as the fields. Switch is
            // primary when ON, light grey when OFF, no dark outline.
            Container(
              decoration: _boxDecoration,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_fieldRadius),
                ),
                thumbColor: const WidgetStatePropertyAll(Colors.white),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : Colors.grey.shade300,
                ),
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
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
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: _fieldHeight,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
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
          ],
        ),
      ),
      ),
    );
  }
}
