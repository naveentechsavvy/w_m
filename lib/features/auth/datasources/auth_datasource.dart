import 'package:firebase_auth/firebase_auth.dart';

class AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) failed,
  }) async {
    await _auth.verifyPhoneNumber(
  phoneNumber: "+91$phoneNumber",

  verificationCompleted: (PhoneAuthCredential credential) async {
    print("✅ verificationCompleted");
    await _auth.signInWithCredential(credential);
  },

  verificationFailed: (FirebaseAuthException e) {
    print("❌ verificationFailed: ${e.code}");
    print("❌ ${e.message}");
    failed(e.message ?? "Verification failed");
  },

  codeSent: (String verificationId, int? resendToken) {
    print("✅ codeSent");
    codeSent(verificationId);
  },

  codeAutoRetrievalTimeout: (String verificationId) {
    print("⏰ timeout");
  },
);
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    return await _auth.signInWithCredential(credential);
  }
}