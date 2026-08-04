import 'package:get/get.dart';

import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import 'app_routes.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/home/screens/choice_screen.dart';
import '../../features/experience/screens/explore_screen.dart';
import '../../features/experience/screens/exp_details_screen.dart';

class AppPages {
  static final pages = [

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.choice,
      page: () => const ChoiceScreen(),
    ),

  GetPage(
    name: AppRoutes.otp,
    page: () => OtpScreen(),
  ),

  GetPage(
    name: AppRoutes.profile,
    page: () => ProfileScreen(),
  ),
  GetPage(
  name: AppRoutes.explore,
  page: () => const ExploreScreen(),
),

GetPage(
  name: AppRoutes.experienceDetails,
  page: () => const ExpDetailsScreen(),
),
  ];
}