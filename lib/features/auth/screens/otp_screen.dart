import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  OtpScreen({super.key});

  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SectionTitle(
                title: "Verify OTP",
                subtitle: "Enter the 6-digit code sent to your mobile.",
              ),

              const SizedBox(height: 40),

              TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: "OTP",
                ),
              ),

              const SizedBox(height: 20),

              Obx(
                () => PrimaryButton(
                  title: "Verify",
                  loading: controller.loading.value,
                  onPressed: controller.verifyOtp,
                ),
              ),

              TextButton(
                onPressed: controller.sendOtp,
                child: const Text("Resend OTP"),
              )
            ],
          ),
        ),
      ),
    );
  }
}