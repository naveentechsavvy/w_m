import 'dart:typed_data';
import '../../../app/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/colors.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String name = "";
  String bio = "";
  String email = "";
  String phoneNumber = "";
  String city = "";
  String gender = "Male";
  String? avatarUrl;

  // ============================================================
  // EDIT DATA
  // ============================================================

  Uint8List? avatarBytes;

  bool isEditing = false;
  bool loading = true;
  bool saving = false;
  bool uploadingAvatar = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadProfile();
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
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedName = prefs.getString("full_name") ?? "";
    final loadedBio = prefs.getString("bio") ?? "";
    final loadedEmail = prefs.getString("email") ?? "";
    final loadedPhone = prefs.getString("phone_number") ?? "";
    final loadedCity = prefs.getString("city") ?? "";
    final loadedGender = prefs.getString("gender") ?? "Male";
    final loadedAvatar = prefs.getString("avatar_url");

    if (!mounted) return;

    setState(() {
      name = loadedName;
      bio = loadedBio;
      email = loadedEmail;
      phoneNumber = loadedPhone;
      city = loadedCity;
      gender = loadedGender;
      avatarUrl = loadedAvatar;

      nameController.text = loadedName;
      bioController.text = loadedBio;
      emailController.text = loadedEmail;
      phoneController.text = loadedPhone;
      cityController.text = loadedCity;

      loading = false;
    });
  }

  // ============================================================
  // START EDITING
  // ============================================================

  void startEditing() {
    setState(() {
      isEditing = true;

      nameController.text = name;
      bioController.text = bio;
      emailController.text = email;
      phoneController.text = phoneNumber;
      cityController.text = city;

      avatarBytes = null;
    });
  }

  // ============================================================
  // CANCEL EDITING
  // ============================================================

  void cancelEditing() {
    setState(() {
      isEditing = false;

      nameController.text = name;
      bioController.text = bio;
      emailController.text = email;
      phoneController.text = phoneNumber;
      cityController.text = city;

      avatarBytes = null;
    });
  }

  // ============================================================
  // PICK PROFILE IMAGE
  // ============================================================

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (!mounted) return;

      setState(() {
        avatarBytes = bytes;
      });
    } catch (e) {
      debugPrint("[ProfileView] Image picker error: $e");

      Get.snackbar(
        "Image Error",
        "Unable to select the profile image.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // ============================================================
  // UPLOAD PROFILE IMAGE
  // ============================================================

  Future<String?> uploadAvatarIfNeeded() async {
    if (avatarBytes == null) {
      return avatarUrl;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      debugPrint("[ProfileView] No logged-in Firebase user.");
      return avatarUrl;
    }

    if (mounted) {
      setState(() {
        uploadingAvatar = true;
      });
    }

    try {
      final ref = FirebaseStorage.instance.ref().child("avatars/$uid.jpg");

      await ref.putData(
        avatarBytes!,
        SettableMetadata(contentType: "image/jpeg"),
      );

      final url = await ref.getDownloadURL();

      debugPrint("[ProfileView] Avatar uploaded successfully.");

      return url;
    } catch (e) {
      debugPrint("[ProfileView] Avatar upload failed: $e");

      Get.snackbar(
        "Photo Upload Failed",
        "Unable to upload your profile photo.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile() async {
    final updatedName = nameController.text.trim();
    final updatedBio = bioController.text.trim();
    final updatedEmail = emailController.text.trim();
    final updatedPhone = phoneController.text.trim();
    final updatedCity = cityController.text.trim();

    if (updatedName.isEmpty) {
      Get.snackbar(
        "Name Required",
        "Please enter your name.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (updatedEmail.isNotEmpty && !GetUtils.isEmail(updatedEmail)) {
      Get.snackbar(
        "Invalid Email",
        "Please enter a valid email address.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (updatedPhone.isEmpty) {
      Get.snackbar(
        "Phone Number Required",
        "Please enter your phone number.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    if (updatedCity.isEmpty) {
      Get.snackbar(
        "City Required",
        "Please enter your city.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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
      final uploadedUrl = await uploadAvatarIfNeeded();

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("full_name", updatedName);
      await prefs.setString("bio", updatedBio);
      await prefs.setString("email", updatedEmail);
      await prefs.setString("phone_number", updatedPhone);
      await prefs.setString("city", updatedCity);
      await prefs.setString("gender", gender);

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        await prefs.setString("avatar_url", uploadedUrl);
      }

      await prefs.setBool("profile_completed", true);

      if (!mounted) return;

      setState(() {
        name = updatedName;
        bio = updatedBio;
        email = updatedEmail;
        phoneNumber = updatedPhone;
        city = updatedCity;

        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          avatarUrl = uploadedUrl;
        }

        avatarBytes = null;
        isEditing = false;
        saving = false;
      });

      Get.snackbar(
        "Profile Updated",
        "Your profile has been updated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint("[ProfileView] Profile update failed: $e");

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      Get.snackbar(
        "Update Failed",
        "Something went wrong while updating your profile.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void openSettings() {
    Get.snackbar(
      "Coming Soon",
      "Settings will be available soon.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'isActive': false});
      }

      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("[ProfileView] Logout Firebase step failed: $e");
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("profile_completed");
    await prefs.remove("is_logged_in");

    Get.offAllNamed(AppRoutes.login);
  }

  // ============================================================
  // PROFILE IMAGE  (letter-avatar fallback, Zomato-style)
  // ============================================================

  Widget profileImage({double radius = 40}) {
    ImageProvider? image;

    if (avatarBytes != null) {
      image = MemoryImage(avatarBytes!);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      image = NetworkImage(avatarUrl!);
    }

    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : "?";

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryTint,
          backgroundImage: image,
          child: image == null
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),

        if (isEditing)
          Positioned(
            bottom: 0,
            right: -2,
            child: GestureDetector(
              onTap: saving ? null : pickAvatar,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: uploadingAvatar
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  // ============================================================
  // EDIT CONTENT (unchanged form UI)
  // ============================================================

  Widget editContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              profileImage(radius: 58),
              const SizedBox(height: 12),
              const Text(
                "Tap to change profile photo",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        _formSectionLabel("BASIC INFORMATION"),

        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: inputDecoration(
            label: "Name",
            hint: "Enter your name",
            icon: Icons.person_outline,
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: bioController,
          maxLines: 3,
          maxLength: 150,
          textCapitalization: TextCapitalization.sentences,
          decoration: inputDecoration(
            label: "Bio",
            hint: "Tell something about yourself",
            icon: Icons.info_outline,
          ),
        ),

        const SizedBox(height: 8),

        _formSectionLabel("CONTACT INFORMATION"),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputDecoration(
            label: "Email Address",
            hint: "Enter your email",
            icon: Icons.email_outlined,
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: inputDecoration(
            label: "Phone Number",
            hint: "Enter your phone number",
            icon: Icons.phone_outlined,
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: cityController,
          textCapitalization: TextCapitalization.words,
          decoration: inputDecoration(
            label: "City",
            hint: "Enter your city",
            icon: Icons.location_on_outlined,
          ),
        ),

        const SizedBox(height: 24),

        _formSectionLabel("PERSONAL DETAILS"),

        DropdownButtonFormField<String>(
          value: gender,
          decoration: inputDecoration(
            label: "Gender",
            icon: Icons.person_outline,
          ),
          items: const [
            DropdownMenuItem(value: "Male", child: Text("Male")),
            DropdownMenuItem(value: "Female", child: Text("Female")),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: saving
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    gender = value;
                  });
                },
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: saving ? null : updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "UPDATE PROFILE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: saving ? null : cancelEditing,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "CANCEL",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _formSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // ZOMATO-STYLE HELPERS
  // ============================================================

  /// Section title with a small colored accent bar, like "Your preferences".
  Widget groupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// A white rounded card that wraps a set of rows with dividers between
  /// them — this replaces the old "one shadow-card per field" look.
  Widget groupCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 56,
                color: Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }

  /// One row inside a group card: icon, label, trailing value + chevron.
  Widget groupRow({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    Color? iconColor,
    Color? labelColor,
    bool showChevron = true,
  }) {
    final color = iconColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value.isEmpty ? "Not added" : value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: labelColor ?? Colors.grey.shade400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIEW CONTENT — Zomato-style layout
  // ============================================================

  Widget viewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // TOP CARD: avatar + name + "Edit profile" link
        // --------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileImage(radius: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Guest" : name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: startEditing,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "Edit profile",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --------------------------------------------------------
        // PERSONAL INFORMATION
        // --------------------------------------------------------

        groupHeader("Personal information"),
        const SizedBox(height: 10),

        groupCard([
          groupRow(
            icon: Icons.email_outlined,
            label: "Email",
            value: email,
            showChevron: false,
          ),
          groupRow(
            icon: Icons.phone_outlined,
            label: "Phone Number",
            value: phoneNumber,
            showChevron: false,
          ),
          groupRow(
            icon: Icons.location_on_outlined,
            label: "City",
            value: city,
            showChevron: false,
          ),
          groupRow(
            icon: Icons.person_outline,
            label: "Gender",
            value: gender,
            showChevron: false,
          ),
        ]),

        const SizedBox(height: 24),

        // --------------------------------------------------------
        // FRIENDS
        // --------------------------------------------------------

        groupHeader("Friends"),
        const SizedBox(height: 10),

        groupCard([
          groupRow(
            icon: Icons.people_outline,
            label: "Friends",
            onTap: () => Get.toNamed(AppRoutes.friends),
          ),
        ]),

        const SizedBox(height: 24),

        // --------------------------------------------------------
        // ORDERS
        // --------------------------------------------------------

        groupHeader("Orders"),
        const SizedBox(height: 10),

        groupCard([
          groupRow(
            icon: Icons.receipt_long_outlined,
            label: "My Orders",
            onTap: () => Get.toNamed(AppRoutes.myOrders),
          ),
        ]),

        const SizedBox(height: 24),

        // --------------------------------------------------------
        // SETTINGS
        // --------------------------------------------------------

        groupHeader("Settings"),
        const SizedBox(height: 10),

        groupCard([
          groupRow(
            icon: Icons.settings_outlined,
            label: "Settings",
            onTap: openSettings,
          ),
          groupRow(
            icon: Icons.logout,
            label: "Logout",
            iconColor: Colors.red,
            labelColor: Colors.red,
            onTap: logout,
          ),
        ]),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: isEditing
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: saving ? null : cancelEditing,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textPrimary,
              ),
              title: const Text(
                "Edit Account",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            )
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: const Text(
                "Profile",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: isEditing ? editContent() : viewContent(),
          ),
        ),
      ),

      bottomNavigationBar: null,
    );
  }
}