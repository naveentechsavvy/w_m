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
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search Experiences",
        prefixIcon: Icon(Icons.search, color: AppColors.primary),
        suffixIcon: showVoiceIcon
            ? IconButton(
                icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                color: AppColors.primary,
                onPressed: onVoiceTap,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}