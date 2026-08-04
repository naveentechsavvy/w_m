import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
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

              const SizedBox(height: 30),

              const Center(
                child: AppLogo(size: 100),
              ),

              const SizedBox(height: 40),

              const SectionTitle(
                title: "Welcome Back",
                subtitle:
                    "Every weekend has a story. Let's start yours.",
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