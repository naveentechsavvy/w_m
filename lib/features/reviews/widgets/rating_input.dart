import 'package:flutter/material.dart';

class RatingInput extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => onChanged(starValue.toDouble()),
          icon: Icon(
            value >= starValue ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFB300),
            size: 36,
          ),
        );
      }),
    );
  }
}