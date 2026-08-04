import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/onboarding_model.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  RxInt currentPage = 0.obs;

  final pages = const [

    OnboardingModel(

      title: "Meet Amazing People",

      subtitle:
          "Discover exciting experiences happening around you every weekend.",

      image: "",

    ),

    OnboardingModel(

      title: "Create Your Experience",

      subtitle:
          "Host treks, cricket, coffee meets, bike rides and much more.",

      image: "",

    ),

    OnboardingModel(

      title: "Food + Fun Together",

      subtitle:
          "Organizers can arrange food while everyone enjoys the experience.",

      image: "",

    ),

  ];

  void next() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void changePage(int index) {
    currentPage.value = index;
  }
}