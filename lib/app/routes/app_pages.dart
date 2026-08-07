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
import '../../features/experience/screens/profile_view_screen.dart';
import '../../features/home/home_placeholder_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/experience/screens/create_meetup_screen.dart';

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
      page: () => const ProfileViewScreen(),
    ),
    GetPage(
      name: AppRoutes.explore,
      page: () => const ExploreScreen(),
    ),
    GetPage(
      name: AppRoutes.experienceDetails,
      page: () => const ExpDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePlaceholderScreen(),
    ),
    GetPage(
      name: AppRoutes.saved,
      page: () => const SavedScreen(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.createExperience,
      page: () => const CreateMeetupScreen(),
    ),
  ];
}