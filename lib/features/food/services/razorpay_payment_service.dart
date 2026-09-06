import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentService {
  late final Razorpay _razorpay;

  /// Called with no arguments once Razorpay reports success and we've
  /// updated the Firestore order status.
  void Function()? onSuccess;

  /// Called with a human-readable message if checkout fails or is
  /// cancelled.
  void Function(String message)? onFailure;

  String? _currentOrderId;

  // TODO: replace with your real Razorpay key before going live.
  static const String _keyId = 'YOUR_RAZORPAY_KEY_ID';

  RazorpayPaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Looks up the order's total in Firestore, then opens Razorpay
  /// checkout for that amount.
  Future<void> startCheckout({
    required String firestoreOrderId,
    required String userName,
    required String userPhone,
  }) async {
    _currentOrderId = firestoreOrderId;

    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(firestoreOrderId)
          .get();

      final total = (orderDoc.data()?['total'] as num?)?.toDouble();
      if (total == null) {
        onFailure?.call('Could not find order total. Please try again.');
        return;
      }

      final options = {
        'key': _keyId,
        'amount': (total * 100).toInt(), // Razorpay expects paise
        'name': userName,
        'description': 'Food order #$firestoreOrderId',
        'prefill': {
          'contact': userPhone,
        },
        'notes': {
          'firestoreOrderId': firestoreOrderId,
        },
      };

      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) {
        print('Razorpay startCheckout error: $e');
      }
      onFailure?.call('Something went wrong while starting payment.');
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    final orderId = _currentOrderId;
    if (orderId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': 'paid',
          'razorpayPaymentId': response.paymentId,
          'razorpayOrderId': response.orderId,
        });
      } catch (e) {
        if (kDebugMode) {
          print('Failed to update order after payment success: $e');
        }
      }
    }
    _currentOrderId = null;
    onSuccess?.call();
  }

  Future<void> _handleError(PaymentFailureResponse response) async {
    final orderId = _currentOrderId;
    if (orderId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({'status': 'failed'});
      } catch (e) {
        if (kDebugMode) {
          print('Failed to update order after payment failure: $e');
        }
      }
    }
    _currentOrderId = null;
    onFailure?.call(response.message ?? 'Payment failed. Please try again.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // No-op for now; you could show a snackbar here if desired.
  }

  void dispose() {
    _razorpay.clear();
  }
}