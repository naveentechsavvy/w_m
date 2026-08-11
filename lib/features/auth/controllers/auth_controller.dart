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

  Future<void> verifyOtp() async {
  loading.value = true;

    try {
      await repository.verifyOtp(
        verificationId: verificationId,
        otp: otpController.text,
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool("is_logged_in", true);
      await prefs.setString(
        "phone_number",
        phoneController.text,
      );
      loading.value = false;

      Get.offAllNamed(AppRoutes.home);
    } catch (_) {
      loading.value = false;
      Get.snackbar("Invalid OTP", "Please try again");
    }
  }
}