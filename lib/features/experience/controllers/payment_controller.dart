import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'subscription_controller.dart';

/// TODO (production): Order creation (`order_id`) and payment signature
/// verification MUST happen on a backend (Cloud Function / server) using
/// your Razorpay secret key — never in the Flutter app. Right now this
/// opens Razorpay checkout directly from the client with a test key and
/// activates premium locally on success, purely so the UI/flow can be
/// built and tested before the backend exists.
class PaymentController extends GetxController {
  late Razorpay _razorpay;

  final SubscriptionController subscriptionController =
      Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : Get.put(SubscriptionController(), permanent: true);

  RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void startCheckout({
    required String planName,
    required int amountInPaise,
  }) {
    isProcessing.value = true;

    // TODO: replace with a real order_id from your backend's
    // POST /create-order endpoint before going live.
    var options = {
      'key': 'YOUR_RAZORPAY_TEST_KEY', // TODO: put your Razorpay test key here
      'amount': amountInPaise,
      'name': 'Weekend Masti',
      'description': '$planName Plan',
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#FF5A3C'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      isProcessing.value = false;
      Get.snackbar("Error", "Could not open payment screen");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // TODO: send response.paymentId / orderId / signature to your backend
    // for verification before activating premium in production.
    await subscriptionController.activatePremium();
    isProcessing.value = false;
    Get.snackbar(
      "Premium Active",
      "You can now create meetups!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    Get.back();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessing.value = false;
    Get.snackbar(
      "Payment Failed",
      response.message ?? "Something went wrong. Please try again.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isProcessing.value = false;
    Get.snackbar("Wallet Selected", response.walletName ?? "");
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
