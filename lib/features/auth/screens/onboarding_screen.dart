import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("onboarding_completed", true);

    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.pages.length,
                onPageChanged: controller.changePage,
                itemBuilder: (context, index) {
                  final item = controller.pages[index];

                  return Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.travel_explore,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 40),

                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Obx(() {
              final lastPage =
                  controller.currentPage.value ==
                      controller.pages.length - 1;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        controller.pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width:
                              controller.currentPage.value == index ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                controller.currentPage.value == index
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (lastPage) {
                            await finishOnboarding();
                          } else {
                            controller.next();
                          }
                        },
                        child: Text(
                          lastPage ? "Get Started" : "Next",
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () async {
                        await finishOnboarding();
                      },
                      child: const Text("Skip"),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}