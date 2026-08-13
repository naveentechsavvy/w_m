import 'dart:async';

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

  // Staged via Interval so the wordmark (see _AnimatedTitle), tagline,
  // and underline animate in sequence off a single controller instead
  // of juggling several separate ones.
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

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _underlineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
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
    // to Home. Users can complete/edit their profile any time via the
    // Profile tab (AppRoutes.editProfile), which still sets the flag when
    // they choose to fill it in.

    await Future.delayed(const Duration(seconds: 2));

    if (!onboardingCompleted) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!loggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.home);
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
                // "Weekend" in dark text color, "Masti" in brand orange,
                // popping in with a soft elastic bounce (see
                // _AnimatedTitle) rather than a flat fade.
                _AnimatedTitle(controller: _controller),

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

                // Underline "draws" left-to-right by animating its width
                // via a FractionallySizedBox clipped against a fixed-max
                // container, rather than animating a raw width value —
                // keeps it centered without manual offset math.
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

/// Pops the "Weekend Masti" wordmark in as a single block, with a soft
/// elastic overshoot (scales past 1.0 then settles back) rather than a
/// flat fade — reads as a deliberate, premium entrance instead of the
/// text simply appearing. "Weekend" stays in the dark text color,
/// "Masti" in brand orange, built as one RichText so both scale/fade
/// together as a single wordmark.
class _AnimatedTitle extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedTitle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );

    final opacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.value,
            child: child,
          ),
        );
      },
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.heading1.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
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

/// Three dots that pulse in a staggered wave, looping continuously until
/// the splash screen navigates away. Runs its own independent
/// AnimationController (rather than reusing the parent's) because it
/// needs to repeat indefinitely while the parent's controller runs once
/// and stops.
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
            // Each dot's pulse is offset by a third of the cycle so they
            // bounce in a left-to-right wave instead of in unison.
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
