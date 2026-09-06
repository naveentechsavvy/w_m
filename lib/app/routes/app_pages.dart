import 'package:get/get.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import 'app_routes.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/name_entry_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/home/screens/choice_screen.dart';
import '../../features/experience/screens/explore_screen.dart';
import '../../features/experience/screens/exp_details_screen.dart';
import '../../features/experience/screens/profile_view_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/experience/screens/create_meetup_screen.dart';
import '../../features/experience/screens/my_meetups_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/bindings/chat_binding.dart';
import '../../features/experience/bindings/experience_details_binding.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/experience/screens/premium_plan_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/experience/screens/participants_screen.dart';
import '../../features/food/screens/food_screen.dart';
import '../../features/food/screens/cart_screen.dart';
import '../../features/food/screens/address_screen.dart';
import '../../features/food/screens/order_success_screen.dart';
import '../../features/food/screens/order_tracking_screen.dart';
import '../../features/food/screens/my_orders_screen.dart';

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
      binding: ExperienceDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.createExperience,
      page: () => const CreateMeetupScreen(),
    ),
    GetPage(
      name: AppRoutes.myMeetups,
      page: () => const MyMeetupsScreen(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.reviews,
      page: () => const ReviewsScreen(),
    ),
    GetPage(
      name: AppRoutes.writeReview,
      page: () => const WriteReviewScreen(),
    ),
    GetPage(
      name: AppRoutes.premiumPlan,
      page: () => const PremiumPlanScreen(),
    ),
    GetPage(
      name: AppRoutes.friends,
      page: () => const FriendsScreen(),
    ),
    GetPage(
      name: AppRoutes.participants,
      page: () => const ParticipantsScreen(),
    ),
    GetPage(
      name: AppRoutes.nameEntry,
      page: () => const NameEntryScreen(),
    ),
    GetPage(
      name: AppRoutes.food,
      page: () => const FoodScreen(),
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => const CartScreen(),
    ),
    GetPage(
      name: AppRoutes.deliveryAddress,
      page: () => const AddressScreen(),
    ),
    GetPage(
      name: AppRoutes.orderSuccess,
      page: () => const OrderSuccessScreen(),
    ),
    GetPage(
      name: AppRoutes.orderTracking,
      page: () => const OrderTrackingScreen(),
    ),
    GetPage(
      name: AppRoutes.myOrders,
      page: () => const MyOrdersScreen(),
    ),
  ];
}