import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Main timeline: 0 -> 2400ms covers everything up through the dots
  // fading in. We then hold the finished logo for another ~300ms before
  // navigating, so the whole splash reads as ~2.7s, matching the plan.
  static const _timelineMs = 2400;
  static const _holdAfterMs = 300;

  late AnimationController _controller;

  // Decorative icons: present almost immediately, very subtle, no motion.
  late Animation<double> _decorOpacity;

  // "weekend" — fades + slides up gently.
  late Animation<double> _weekendOpacity;
  late Animation<Offset> _weekendSlide;

  // "masti" — left-to-right reveal, then a tiny "settle" scale.
  late Animation<double> _mastiReveal;
  late Animation<double> _mastiScale;

  // Underline — width 0 -> full.
  late Animation<double> _underlineWidth;

  // Tagline — fade + slight upward move.
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  // Loading dots container — fades in late, dots animate on their own.
  late Animation<double> _dotsOpacity;

  // Helper: converts a start/end time in seconds (per the animation plan)
  // into a 0..1 Interval against the 2400ms timeline.
  Interval _at(double startSec, double endSec, {Curve curve = Curves.easeOut}) {
    final total = _timelineMs / 1000;
    return Interval(
      (startSec / total).clamp(0.0, 1.0),
      (endSec / total).clamp(0.0, 1.0),
      curve: curve,
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _timelineMs),
    );

    // 0.0s: decorative icons are basically already there, just a quick
    // settle-in so they don't hard-pop on frame one.
    _decorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(0.0, 0.15)),
    );

    // 0.2 - 0.8s: "weekend" fades + slides up slightly.
    _weekendOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(0.2, 0.8)),
    );
    _weekendSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: _at(0.2, 0.8, curve: Curves.easeOut)),
    );

    // 0.5 - 1.1s: "masti" reveals left-to-right.
    _mastiReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(0.5, 1.1, curve: Curves.easeInOut)),
    );
    // 0.95 - 1.15s: tiny settle scale right as the reveal finishes.
    _mastiScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(0.95, 1.15, curve: Curves.easeOut)),
    );

    // 1.0 - 1.4s: underline expands.
    _underlineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(1.0, 1.4)),
    );

    // 1.2 - 1.8s: tagline fades + drifts up.
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(1.2, 1.8)),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: _at(1.2, 1.8)),
    );

    // 1.6 - 2.4s: loading dots container fades in (dots animate internally).
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _at(1.6, 2.4)),
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

    // Hold on the finished logo for a beat after the entrance animation
    // completes (2.4s) before navigating, so the total splash is ~2.7s,
    // matching the animation timeline above.
    await Future.delayed(
      const Duration(milliseconds: _timelineMs + _holdAfterMs),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative icon cluster — calm, static, very subtle.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(opacity: _decorOpacity.value, child: child);
              },
              child: _DecorLayer(size: size),
            ),
          ),

          // Center content: brand name, tagline, underline, loading dots.
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BrandTitle(
                      weekendOpacity: _weekendOpacity.value,
                      weekendSlide: _weekendSlide,
                      mastiReveal: _mastiReveal.value,
                      mastiScale: _mastiScale.value,
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
                    Opacity(
                      opacity: _dotsOpacity.value,
                      child: const _LoadingDots(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "weekend masti" brand title.
/// - "weekend" fades + slides up.
/// - "masti" reveals left-to-right, then does a tiny 0.96 -> 1.0 settle.
class _BrandTitle extends StatelessWidget {
  final double weekendOpacity;
  final Animation<Offset> weekendSlide;
  final double mastiReveal;
  final double mastiScale;

  const _BrandTitle({
    required this.weekendOpacity,
    required this.weekendSlide,
    required this.mastiReveal,
    required this.mastiScale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Opacity(
          opacity: weekendOpacity.clamp(0.0, 1.0),
          child: SlideTransition(
            position: weekendSlide,
            child: Text(
              "weekend ",
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        Transform.scale(
          scale: mastiScale,
          alignment: Alignment.centerLeft,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: mastiReveal.clamp(0.0, 1.0),
              child: Text(
                "masti",
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle background layer of category-themed icons (trek, cricket, mic,
/// cycling, coffee, networking, music, gaming, small dots) scattered
/// around the edges of the screen, behind the brand.
/// All icons use AppColors.primary / AppColors.textPrimary — no new colors.
class _DecorLayer extends StatelessWidget {
  final Size size;

  const _DecorLayer({required this.size});

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;

    return Stack(
      children: [
        _icon(Icons.hiking, left: w * 0.10, top: h * 0.12, sz: 44, op: 0.18),
        _icon(Icons.sports_cricket, right: w * 0.12, top: h * 0.16, sz: 40, op: 0.20),
        _icon(Icons.mic_none_rounded, left: w * 0.14, top: h * 0.30, sz: 34, op: 0.18),
        _icon(Icons.directions_bike_outlined, right: w * 0.10, top: h * 0.32, sz: 40, op: 0.16),
        _icon(Icons.local_cafe_outlined, left: w * 0.16, bottom: h * 0.26, sz: 38, op: 0.18),
        _icon(Icons.groups_outlined, right: w * 0.14, bottom: h * 0.22, sz: 34, op: 0.16),
        _icon(Icons.music_note_outlined, left: w * 0.08, bottom: h * 0.12, sz: 30, op: 0.18),
        _icon(Icons.sports_esports_outlined, right: w * 0.08, bottom: h * 0.10, sz: 32, op: 0.16),

        _dot(left: w * 0.28, top: h * 0.20, sz: 6),
        _dot(right: w * 0.30, top: h * 0.42, sz: 5),
        _dot(left: w * 0.06, top: h * 0.46, sz: 5),
        _dot(right: w * 0.20, bottom: h * 0.34, sz: 6),
        _dot(left: w * 0.32, bottom: h * 0.16, sz: 5),
        _dot(right: w * 0.06, bottom: h * 0.30, sz: 5),
      ],
    );
  }

  Widget _icon(
    IconData icon, {
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double sz,
    required double op,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Icon(icon, size: sz, color: AppColors.primary.withOpacity(op)),
    );
  }

  Widget _dot({double? left, double? right, double? top, double? bottom, required double sz}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textPrimary.withOpacity(0.12),
        ),
      ),
    );
  }
}

/// Loading dots that light up in sequence (like a typing indicator) and
/// loop gently, instead of all three appearing/pulsing at once.
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
      duration: const Duration(milliseconds: 1400),
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
            final delay = index * 0.18;
            final t = (_controller.value - delay) % 1.0;
            final phase = t < 0.5 ? (t / 0.5) : (1 - (t - 0.5) / 0.5);
            final opacity = 0.35 + 0.65 * phase;
            final scale = 1.0 + 0.35 * phase;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
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





