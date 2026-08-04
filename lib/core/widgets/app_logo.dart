import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.travel_explore,
        color: Colors.white,
        size: 55,
      ),
    );
  }
}