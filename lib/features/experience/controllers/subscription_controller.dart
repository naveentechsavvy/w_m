import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TEMPORARY local subscription status holder.
/// TODO: Replace with Firestore-backed `subscriptionStatus` /
/// `subscriptionEndDate` fields on the user document once the backend
/// (order creation + payment signature verification) is in place.
/// For now this just remembers premium status on-device via
/// SharedPreferences, so the Create-button gating flow can be built
/// and tested end-to-end before Firestore is wired in.
class SubscriptionController extends GetxController {
  final RxBool isPremium = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium.value = prefs.getBool("is_premium") ?? false;
  }

  Future<void> activatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_premium", true);
    isPremium.value = true;
  }

  Future<void> deactivatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_premium", false);
    isPremium.value = false;
  }
}
