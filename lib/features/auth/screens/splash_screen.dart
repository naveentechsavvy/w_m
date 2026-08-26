import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _underlineWidth;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _underlineWidth = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    checkUser();
  }

  /// Profile is complete when the user has entered a real name.
  Future<bool> _isProfileComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      if (data == null) return false;

      final name = data['name'] as String?;

      final hasRealName = name != null &&
          name.trim().isNotEmpty &&
          !name.startsWith('User ');

      return hasRealName;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    final bool loggedIn = prefs.getBool("is_logged_in") ?? false;

    final bool onboardingCompleted =
        prefs.getBool("onboarding_completed") ?? false;

    bool profileComplete = false;
    if (loggedIn) {
      profileComplete = await _isProfileComplete();
    }

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    if (!onboardingCompleted) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!loggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else if (!profileComplete) {
      Get.offAllNamed(AppRoutes.nameEntry);
    } else {
      Get.offAllNamed(AppRoutes.choice);
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
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedTitle(
                  controller: _controller,
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      "Every Weekend Deserves a Story",
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ClipRect(
                  child: Align(
                    alignment: Alignment.center,
                    widthFactor: _underlineWidth.value,
                    child: Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const _LoadingDots(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Animated Weekend Masti title
class _AnimatedTitle extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedTitle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          children: [
            TextSpan(
              text: "Weekend ",
              style: TextStyle(color: AppColors.textPrimary),
            ),
            TextSpan(
              text: "Masti",
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated loading dots
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final scale = t < 0.5
                ? 1.0 + (0.6 * (t / 0.5))
                : 1.6 - (0.6 * ((t - 0.5) / 0.5));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}