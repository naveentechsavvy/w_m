import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final nameController = TextEditingController();
  final occupationController = TextEditingController();
  final cityController = TextEditingController();

  String gender = "Male";

  bool isEditMode = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExistingProfile();
  }

  Future<void> loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final alreadyCompleted = prefs.getBool("profile_completed") ?? false;

    nameController.text = prefs.getString("full_name") ?? "";
    occupationController.text = prefs.getString("occupation") ?? "";
    cityController.text = prefs.getString("city") ?? "";
    gender = prefs.getString("gender") ?? "Male";

    setState(() {
      isEditMode = alreadyCompleted;
      loading = false;
    });
  }

  Future<void> saveProfile() async {

    if (nameController.text.isEmpty ||
        occupationController.text.isEmpty ||
        cityController.text.isEmpty) {

      Get.snackbar(
        "Missing Information",
        "Please fill all fields",
      );

      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("full_name", nameController.text);
    await prefs.setString("occupation", occupationController.text);
    await prefs.setString("city", cityController.text);
    await prefs.setString("gender", gender);

    await prefs.setBool("profile_completed", true);

    if (isEditMode) {
      Get.back(result: true);
    } else {
      Get.offAllNamed(AppRoutes.explore);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: isEditMode
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Edit Profile",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            )
          : null,

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 40),

              if (!isEditMode) ...[
                Text(
                  "Complete Profile",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Tell us a little about yourself.",
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),
              ],

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: const [

                  DropdownMenuItem(
                    value: "Male",
                    child: Text("Male"),
                  ),

                  DropdownMenuItem(
                    value: "Female",
                    child: Text("Female"),
                  ),

                  DropdownMenuItem(
                    value: "Other",
                    child: Text("Other"),
                  ),

                ],
                onChanged: (value) {

                  setState(() {
                    gender = value!;
                  });

                },
              ),

              const SizedBox(height: 20),

              TextField(
                controller: occupationController,
                decoration: const InputDecoration(
                  labelText: "Occupation",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: "City",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(

                  onPressed: saveProfile,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),

                  child: Text(
                    isEditMode ? "Save Changes" : "Continue",
                    style: const TextStyle(
                      fontSize: 18,
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