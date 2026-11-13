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

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.travel_explore,
                                    size: 76,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 44),

                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
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
                                    : AppColors.divider,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
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
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(64, 44),
                      ),
                      child: const Text("Skip"),
                    ),
                  ],
                ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}