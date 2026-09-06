import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: outerConstraints.maxHeight - 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChoiceCard(
                          title: 'Explore',
                          subtitle:
                              "Discover what's happening around you today.",
                          buttonText: 'Explore',
                          accent: AppColors.primary,
                          illustrationAsset:
                              'assets/illustrations/map_illustration.svg',
                          onTap: () {
                            Get.offNamed(AppRoutes.home);
                          },
                        ),

                        const SizedBox(height: 14),

                        _ChoiceCard(
                          title: 'Order Food',
                          subtitle:
                              'Delicious food, delivered to your place.',
                          buttonText: 'Order Food',
                          accent: const Color(0xFFC9861B),
                          illustrationAsset:
                              'assets/illustrations/food_illustration.svg',
                          onTap: () {
                            Get.toNamed(AppRoutes.food);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// CHOICE CARD — compact, illustration never cropped, lighter button
// ================================================================

class _ChoiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final Color accent;
  final String illustrationAsset;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.accent,
    required this.illustrationAsset,
    required this.onTap,
  });

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Lighter tint of the accent color for the button background,
    // so it reads as soft/pastel instead of a dark solid block.
    final Color lightButtonColor =
        Color.lerp(widget.accent, Colors.white, 0.18) ?? widget.accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;

            final textBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: isWide ? 160 : double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightButtonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.buttonText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: isWide
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 3, child: textBlock),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 110,
                              child: SvgPicture.asset(
                                widget.illustrationAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 120,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: SvgPicture.asset(
                            widget.illustrationAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                          child: textBlock,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}