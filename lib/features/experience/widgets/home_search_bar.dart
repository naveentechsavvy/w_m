import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class HomeSearchBar extends StatelessWidget {
  final bool showVoiceIcon;
  final bool isListening;
  final TextEditingController? searchController;
  final VoidCallback? onVoiceTap;

  const HomeSearchBar({
    super.key,
    this.showVoiceIcon = false,
    this.isListening = false,
    this.searchController,
    this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.divider),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Search Experiences",
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: showVoiceIcon
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    tooltip: isListening ? "Stop voice search" : "Voice search",
                    style: IconButton.styleFrom(
                      backgroundColor: isListening
                          ? AppColors.primaryTint
                          : Colors.transparent,
                    ),
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                    color: AppColors.primary,
                    onPressed: onVoiceTap,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
