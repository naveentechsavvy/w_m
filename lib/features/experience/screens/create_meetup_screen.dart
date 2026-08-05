import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
  bool foodAvailable = false;
  bool isPrivate = false;

  Uint8List? bannerBytes;
  bool saving = false;

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

  bool validate() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar("Missing Title", "Please enter a meetup title");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      Get.snackbar("Missing Location", "Please enter a location");
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

    // Dummy save for now — will be replaced with Firestore write
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
      foodAvailable: foodAvailable,
      description: descriptionController.text.trim(),
      isPrivate: isPrivate,
      participants: const [],
      gallery: const [],
    );

    await Future.delayed(const Duration(milliseconds: 400)); // simulated save

    controller.addExperience(newExperience);

    setState(() {
      saving = false;
    });

    Get.back();
    Get.snackbar(
      "Meetup Created",
      "\"${newExperience.title}\" is now live",
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
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

            // Banner upload
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

            fieldLabel("DESCRIPTION"),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: fieldDecoration("What's this meetup about?"),
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

            fieldLabel("LOCATION"),
            TextField(
              controller: locationController,
              decoration: fieldDecoration("Area / City")
                  .copyWith(prefixIcon: const Icon(Icons.location_on_outlined)),
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

            const SizedBox(height: 18),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                "Food Available",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: foodAvailable,
              onChanged: (value) {
                setState(() {
                  foodAvailable = value;
                });
              },
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                "Private Meetup",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Only people you approve can join",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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