import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';

/// Shown after every OTP login. For a brand new account this is a
/// real ask ("what's your name?"); for a returning user, their
/// existing name is pre-filled so it's effectively a single tap to
/// continue, while still letting them change it if they want.
class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _nameController = TextEditingController();
  bool _loadingExisting = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingName();
  }

  Future<void> _loadExistingName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      final existingName = data?['name'] as String?;

      // Don't pre-fill the auto-generated "User <phone>" placeholder —
      // only a real, previously-entered name counts as "existing".
      if (existingName != null && !existingName.startsWith('User ')) {
        _nameController.text = existingName;
      }
    }

    if (!mounted) return;
    setState(() => _loadingExisting = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        "Name Required",
        "Please enter your name to continue.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'name': name}, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("full_name", name);
      await prefs.setBool("profile_completed", true);

      if (!mounted) return;
      Get.offAllNamed(AppRoutes.choice);
    } catch (e) {
      debugPrint("[NameEntry] Failed to save name: $e");
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        "Something Went Wrong",
        "Could not save your name. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const SectionTitle(
                title: "What should we call you?",
                subtitle:
                    "Just your name for now \u2014 you can add the rest "
                    "of your profile anytime later.",
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                title: "Continue",
                loading: _saving,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}