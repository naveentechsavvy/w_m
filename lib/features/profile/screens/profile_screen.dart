import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nameController =
      TextEditingController();

  final bioController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final cityController =
      TextEditingController();

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String gender = "Male";

  Uint8List? avatarBytes;

  String? avatarUrl;

  bool uploadingAvatar = false;
  bool loading = true;
  bool saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadExistingProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD EXISTING PROFILE
  // ============================================================

  Future<void> loadExistingProfile() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    nameController.text =
        prefs.getString(
              "full_name",
            ) ??
            "";

    bioController.text =
        prefs.getString(
              "bio",
            ) ??
            "";

    emailController.text =
        prefs.getString(
              "email",
            ) ??
            "";

    phoneController.text =
        prefs.getString(
              "phone_number",
            ) ??
            "";

    cityController.text =
        prefs.getString(
              "city",
            ) ??
            "";

    gender =
        prefs.getString(
              "gender",
            ) ??
            "Male";

    avatarUrl =
        prefs.getString(
      "avatar_url",
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ============================================================
  // PICK AVATAR
  // ============================================================

  Future<void> pickAvatar() async {
    try {
      final picker =
          ImagePicker();

      final picked =
          await picker.pickImage(
        source:
            ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (picked == null) {
        return;
      }

      final bytes =
          await picked.readAsBytes();

      if (!mounted) return;

      setState(() {
        avatarBytes = bytes;
      });
    } catch (e) {
      debugPrint(
        "[ProfileScreen] Image picker error: $e",
      );

      Get.snackbar(
        "Photo Error",
        "Unable to select profile photo.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.red,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // ============================================================
  // UPLOAD AVATAR
  // ============================================================

  Future<String?> uploadAvatarIfNeeded() async {
    if (avatarBytes == null) {
      return avatarUrl;
    }

    final uid =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    if (uid == null) {
      debugPrint(
        "[ProfileScreen] No logged-in user.",
      );

      return avatarUrl;
    }

    if (mounted) {
      setState(() {
        uploadingAvatar = true;
      });
    }

    try {
      final ref =
          FirebaseStorage
              .instance
              .ref()
              .child(
                "avatars/$uid.jpg",
              );

      await ref.putData(
        avatarBytes!,
        SettableMetadata(
          contentType:
              "image/jpeg",
        ),
      );

      final url =
          await ref.getDownloadURL();

      return url;
    } catch (e) {
      debugPrint(
        "[ProfileScreen] Avatar upload failed: $e",
      );

      Get.snackbar(
        "Photo Upload Failed",
        "Your profile information can still be saved.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.red,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );

      return avatarUrl;
    } finally {
      if (mounted) {
        setState(() {
          uploadingAvatar = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE INITIAL PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    final name =
        nameController.text.trim();

    final bio =
        bioController.text.trim();

    final email =
        emailController.text.trim();

    final phone =
        phoneController.text.trim();

    final city =
        cityController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      Get.snackbar(
        "Name Required",
        "Please enter your name.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.orange,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (phone.isEmpty) {
      Get.snackbar(
        "Phone Number Required",
        "Please enter your phone number.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.orange,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (city.isEmpty) {
      Get.snackbar(
        "City Required",
        "Please enter your city.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.orange,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (email.isNotEmpty &&
        !GetUtils.isEmail(email)) {
      Get.snackbar(
        "Invalid Email",
        "Please enter a valid email address.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.orange,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    try {
      // --------------------------------------------------------
      // UPLOAD PHOTO
      // --------------------------------------------------------

      final uploadedUrl =
          await uploadAvatarIfNeeded();

      // --------------------------------------------------------
      // SAVE LOCALLY
      // --------------------------------------------------------

      final prefs =
          await SharedPreferences
              .getInstance();

      await prefs.setString(
        "full_name",
        name,
      );

      await prefs.setString(
        "bio",
        bio,
      );

      await prefs.setString(
        "email",
        email,
      );

      await prefs.setString(
        "phone_number",
        phone,
      );

      await prefs.setString(
        "city",
        city,
      );

      await prefs.setString(
        "gender",
        gender,
      );

      if (uploadedUrl != null &&
          uploadedUrl.isNotEmpty) {
        await prefs.setString(
          "avatar_url",
          uploadedUrl,
        );
      }

      await prefs.setBool(
        "profile_completed",
        true,
      );

      // --------------------------------------------------------
      // GO TO APP
      // --------------------------------------------------------

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      Get.offAllNamed(
        AppRoutes.explore,
      );
    } catch (e) {
      debugPrint(
        "[ProfileScreen] Save failed: $e",
      );

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      Get.snackbar(
        "Save Failed",
        "Unable to save your profile.",
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.red,
        colorText:
            Colors.white,
        margin:
            const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget profileImage() {
    ImageProvider? image;

    if (avatarBytes != null) {
      image =
          MemoryImage(
        avatarBytes!,
      );
    } else if (avatarUrl != null &&
        avatarUrl!.isNotEmpty) {
      image =
          NetworkImage(
        avatarUrl!,
      );
    }

    return GestureDetector(
      onTap:
          saving
              ? null
              : pickAvatar,
      child: Stack(
        clipBehavior:
            Clip.none,
        children: [
          CircleAvatar(
            radius: 58,
            backgroundColor:
                AppColors.primaryTint,
            backgroundImage:
                image,
            child: image ==
                    null
                ? const Icon(
                    Icons.person,
                    size: 58,
                    color:
                        AppColors.primary,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: -2,
            child: Container(
              padding:
                  const EdgeInsets.all(
                9,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    AppColors.primary,
                shape:
                    BoxShape.circle,
              ),
              child:
                  uploadingAvatar
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .camera_alt_outlined,
                          color:
                              Colors.white,
                          size: 18,
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (loading) {
      return const Scaffold(
        backgroundColor:
            AppColors.background,
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Complete Profile",
          style: TextStyle(
            color:
                AppColors.textPrimary,
            fontWeight:
                FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------

              const Text(
                "Tell us about yourself",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textPrimary,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                "Add your details to complete your profile.",
                style: TextStyle(
                  fontSize: 14,
                  color:
                      AppColors.textSecondary,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // --------------------------------------------------
              // PHOTO
              // --------------------------------------------------

              Center(
                child: Column(
                  children: [
                    profileImage(),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      "Tap to add profile photo",
                      style:
                          TextStyle(
                        fontSize: 13,
                        color:
                            AppColors
                                .primary,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // --------------------------------------------------
              // BASIC INFORMATION
              // --------------------------------------------------

              const Text(
                "BASIC INFORMATION",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextField(
                controller:
                    nameController,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    fieldDecoration(
                  label:
                      "Name",
                  hint:
                      "Enter your name",
                  icon:
                      Icons
                          .person_outline,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    bioController,
                maxLines: 3,
                maxLength: 150,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    fieldDecoration(
                  label:
                      "Bio",
                  hint:
                      "Tell something about yourself",
                  icon:
                      Icons
                          .info_outline,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // --------------------------------------------------
              // CONTACT
              // --------------------------------------------------

              const Text(
                "CONTACT INFORMATION",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              TextField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType
                        .emailAddress,
                decoration:
                    fieldDecoration(
                  label:
                      "Email Address",
                  hint:
                      "Enter your email",
                  icon:
                      Icons
                          .email_outlined,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    fieldDecoration(
                  label:
                      "Phone Number",
                  hint:
                      "Enter your phone number",
                  icon:
                      Icons
                          .phone_outlined,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    cityController,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    fieldDecoration(
                  label:
                      "City",
                  hint:
                      "Enter your city",
                  icon:
                      Icons
                          .location_on_outlined,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // --------------------------------------------------
              // PERSONAL DETAILS
              // --------------------------------------------------

              const Text(
                "PERSONAL DETAILS",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              DropdownButtonFormField<
                  String>(
                value: gender,
                decoration:
                    fieldDecoration(
                  label:
                      "Gender",
                  icon:
                      Icons
                          .person_outline,
                ),
                items: const [
                  DropdownMenuItem(
                    value:
                        "Male",
                    child:
                        Text(
                      "Male",
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        "Female",
                    child:
                        Text(
                      "Female",
                    ),
                  ),
                  DropdownMenuItem(
                    value:
                        "Other",
                    child:
                        Text(
                      "Other",
                    ),
                  ),
                ],
                onChanged:
                    saving
                        ? null
                        : (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setState(
                              () {
                                gender =
                                    value;
                              },
                            );
                          },
              ),

              const SizedBox(
                height: 30,
              ),

              // --------------------------------------------------
              // SAVE
              // --------------------------------------------------

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      saving
                          ? null
                          : saveProfile,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors
                            .primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                  child:
                      saving
                          ? const SizedBox(
                              width:
                                  23,
                              height:
                                  23,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              "CONTINUE",
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .bold,
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