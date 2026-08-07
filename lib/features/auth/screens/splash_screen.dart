import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    checkUser();
  }

  Future<void> checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    bool loggedIn = prefs.getBool("is_logged_in") ?? false;
    bool onboardingCompleted =
        prefs.getBool("onboarding_completed") ?? false;

    // NOTE: "profile_completed" is intentionally NOT checked here anymore.
    // Previously an incomplete profile sent the user to AppRoutes.profile
    // (ProfileViewScreen) on every relaunch, with no way to clear the flag
    // from that screen — causing a permanent redirect loop back to Profile.
    // Per product decision, profile completion should never block access
    // to Explore. Users can complete/edit their profile any time via the
    // Profile tab (AppRoutes.editProfile), which still sets the flag when
    // they choose to fill it in.

    await Future.delayed(const Duration(seconds: 2));

    if (!onboardingCompleted) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!loggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.explore);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _animation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Replace this with your logo later
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.travel_explore,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Weekend Masti",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Every Weekend Deserves a Story",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
