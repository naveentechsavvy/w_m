import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository repository = AuthRepository();

  final phoneController = TextEditingController();

  final otpController = TextEditingController();

  RxBool loading = false.obs;

  String verificationId = "";

  Future<void> sendOtp() async {
    if (phoneController.text.length != 10) {
      Get.snackbar("Invalid", "Enter a valid mobile number");
      return;
    }

    loading.value = true;

    await repository.verifyPhone(
      phone: phoneController.text,
      codeSent: (id) {
        verificationId = id;
        loading.value = false;
        Get.toNamed("/otp");
      },
      failed: (message) {
        loading.value = false;
        Get.snackbar("Error", message);
      },
    );
  }

  /// Ensures a `users/{uid}` profile document exists for every account,
  /// right after login/signup succeeds.
  ///
  /// Uses SetOptions(merge: true) so this never overwrites a name the
  /// person already set — it only fills in fields that don't exist yet.
  Future<void> _ensureUserProfile(String phone) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final existing = await userRef.get();
    final existingData = existing.data();

    final Map<String, dynamic> data = {
      'phone': phone,
    };

    if (existingData == null || existingData['name'] == null) {
      data['name'] = 'User $phone';
    }

    if (existingData == null) {
      data['createdAt'] = Timestamp.now();
    }

    await userRef.set(data, SetOptions(merge: true));
  }

  Future<void> verifyOtp() async {
    loading.value = true;

    try {
      await repository.verifyOtp(
        verificationId: verificationId,
        otp: otpController.text,
      );

      await _ensureUserProfile(phoneController.text);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool("is_logged_in", true);
      await prefs.setString(
        "phone_number",
        phoneController.text,
      );

      loading.value = false;

      // Every login (new or returning) goes through Name Entry.
      // NameEntryScreen pre-fills the existing name for returning
      // users, so it's a single tap for them, and a real ask for
      // brand new accounts.
      Get.offAllNamed(AppRoutes.nameEntry);
    } catch (_) {
      loading.value = false;
      Get.snackbar("Invalid OTP", "Please try again");
    }
  }
}