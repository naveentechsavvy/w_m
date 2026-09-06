import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 60),

              const Text(
                "Log in or sign up",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              AppTextField(
                controller: controller.phoneController,
                label: "Mobile Number",
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 30),

              Obx(() {
                return PrimaryButton(
                  title: "Continue",
                  loading: controller.loading.value,
                  onPressed: controller.sendOtp,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}