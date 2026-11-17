import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../profile/widgets/interests_picker.dart';

/// Signup step for NEW users only, shown right after Name entry.
/// Saves users/{uid}.interests (labels only) and then continues to the
/// same screen Name entry used to go to (Choice).
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  List<String> _selected = const [];
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected.length < kMinInterests) {
      Get.snackbar(
        "Pick a few more",
        kPickMoreInterestsMessage,
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
            .set({'interests': _selected}, SetOptions(merge: true));
      }
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.choice);
    } catch (e) {
      debugPrint("[Interests] Failed to save interests: $e");
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        "Something Went Wrong",
        "Could not save your interests. Please try again.",
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const SectionTitle(
                    title: "What do you love doing?",
                    subtitle: "Pick at least 3 so we can find meetups you'll enjoy.",
                  ),
                  const SizedBox(height: 24),
                  InterestsPicker(
                    enabled: !_saving,
                    onChanged: (list) => setState(() => _selected = list),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    title: "Continue",
                    loading: _saving,
                    onPressed: _continue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
