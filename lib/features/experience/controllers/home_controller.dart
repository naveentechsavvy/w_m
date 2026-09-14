import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/experience_model.dart';
import '../repositories/experience_repository.dart';

class HomeController extends GetxController {
  final ExperienceRepository repository = ExperienceRepository();

  RxBool isLoading = false.obs;
  RxList<Experience> allExperiences = <Experience>[].obs;

  // Voice search
  final SpeechToText _speech = SpeechToText();
  final RxBool isListening = false.obs;
  final TextEditingController searchTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  Future<void> loadHome() async {
    isLoading.value = true;
    try {
      final result = await repository.getAllMeetups();
      allExperiences.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startVoiceSearch() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      Get.snackbar('Permission needed', 'Microphone access is required for voice search');
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (error) {
        isListening.value = false;
        debugPrint('Speech error: $error');
      },
    );

    if (available) {
      isListening.value = true;
      _speech.listen(
        onResult: (result) {
          searchTextController.text = result.recognizedWords;
          searchTextController.selection = TextSelection.fromPosition(
            TextPosition(offset: searchTextController.text.length),
          );
        },
      );
    } else {
      Get.snackbar('Not available', 'Speech recognition is not available on this device');
    }
  }

  void stopVoiceSearch() {
    _speech.stop();
    isListening.value = false;
  }

  String get userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return "there";
  }

  Experience? get upcomingMeetup {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // FIX: previously only checked `date.isAfter(now)`, which doesn't
    // account for cancelled meetups — a cancelled meetup whose original
    // start time hadn't arrived yet would still show here (e.g. a
    // meetup cancelled minutes before it was due to start). Now also
    // excludes cancelled meetups, and uses `effectiveEndDate` instead
    // of the raw start `date` so a meetup that's currently in progress
    // (started but not yet ended) still correctly counts as "upcoming"
    // here too — matching the same status logic used in My Meetups and
    // the website.
    final mine = allExperiences
        .where((e) =>
            !e.cancelled &&
            e.effectiveEndDate.isAfter(DateTime.now()) &&
            (e.createdBy == uid || e.participants.contains(uid)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return mine.isEmpty ? null : mine.first;
  }

  @override
  void onClose() {
    _speech.stop();
    searchTextController.dispose();
    super.onClose();
  }
}