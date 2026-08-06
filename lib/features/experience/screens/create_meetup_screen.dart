import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/experience_controller.dart';
import '../models/experience_model.dart';

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final controller = Get.find<ExperienceController>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final seatsController = TextEditingController();

  String selectedCategory = "Adventure";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isPrivate = false;

  Uint8List? bannerBytes;
  bool saving = false;

  // NEW — real coordinates selected on the map
  double? selectedLat;
  double? selectedLng;

  final List<String> categoryOptions = const [
    "Adventure",
    "Coffee",
    "Cricket",
    "Music",
    "Cycling",
    "Food",
  ];

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

  // ===========================
  // Location picker (bottom sheet) — now a real interactive Google Map
  // ===========================
  Future<void> pickLocation() async {
    LatLng initialPosition = const LatLng(17.3850, 78.4867); // Hyderabad default
    if (selectedLat != null && selectedLng != null) {
      initialPosition = LatLng(selectedLat!, selectedLng!);
    }

    LatLng pickedPosition = initialPosition;
    GoogleMapController? mapController;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> useCurrentLocation() async {
              try {
                final permission = await Geolocator.checkPermission();
                LocationPermission finalPermission = permission;
                if (permission == LocationPermission.denied) {
                  finalPermission = await Geolocator.requestPermission();
                }
                if (finalPermission == LocationPermission.denied ||
                    finalPermission == LocationPermission.deniedForever) {
                  Get.snackbar("Location Permission Needed",
                      "Please allow location access to use this feature");
                  return;
                }

                final position = await Geolocator.getCurrentPosition();
                final newPos = LatLng(position.latitude, position.longitude);
                setModalState(() {
                  pickedPosition = newPos;
                });
                mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
              } catch (e) {
                Get.snackbar("Location Error", e.toString());
              }
            }

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
                      "Tap on the map to drop a pin at the exact spot",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: initialPosition,
                            zoom: 14,
                          ),
                          onMapCreated: (controllerParam) {
                            mapController = controllerParam;
                          },
                          onTap: (tappedPosition) {
                            setModalState(() {
                              pickedPosition = tappedPosition;
                            });
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId("selected"),
                              position: pickedPosition,
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: useCurrentLocation,
                      icon: const Icon(Icons.my_location, color: AppColors.primary),
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
          },
        );
      },
    );

    if (result != null) {
      final lat = result['lat'] as double;
      final lng = result['lng'] as double;
      setState(() {
        selectedLat = lat;
        selectedLng = lng;
        // No geocoding package yet, so we display coordinates directly.
        // Add the `geocoding` package later if you want a readable
        // address like "Banjara Hills, Hyderabad" instead.
        locationController.text = "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
      });
    }
  }

  bool validate() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar("Missing Title", "Please enter a meetup title");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      Get.snackbar("Missing Location", "Please set a location");
      return false;
    }
    if (selectedDate == null) {
      Get.snackbar("Missing Date", "Please select a date");
      return false;
    }
    if (selectedTime == null) {
      Get.snackbar("Missing Time", "Please select a time");
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

    final newExperience = Experience(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      category: selectedCategory,
      location: locationController.text.trim(),
      image: "assets/experiences/trek.webp", // placeholder until real upload wired
      date: combinedDate,
      price: double.parse(priceController.text.trim()),
      joined: 0,
      seats: int.parse(seatsController.text.trim()),
      foodAvailable: false,
      description: descriptionController.text.trim(),
      isPrivate: isPrivate,
      participants: const [],
      gallery: const [],
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

      // Navigate to My Meetups (Created tab is index 0 by default)
      // instead of just popping back, so the user immediately sees
      // confirmation that the meetup was created.
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
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: fieldDecoration("Select category"),
              items: categoryOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
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
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
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
                const SizedBox(width: 12),
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
                                ? "Select time"
                                : selectedTime!.format(context),
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
