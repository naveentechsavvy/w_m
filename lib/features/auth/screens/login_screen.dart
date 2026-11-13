import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    "Log in or sign up",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Enter your mobile number. We'll send you a one-time code.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  AppTextField(
                    controller: controller.phoneController,
                    label: "Mobile Number",
                    keyboardType: TextInputType.phone,
                    prefix: const Icon(Icons.call_outlined),
                  ),

                  const SizedBox(height: 24),

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
        ),
      ),
    );
  }
}
