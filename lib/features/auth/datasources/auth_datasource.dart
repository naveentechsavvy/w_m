import 'package:cloud_firestore/cloud_firestore.dart';
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
        final userCredential = await _auth.signInWithCredential(credential);
        await _markUserActive(userCredential.user?.uid);
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

    final userCredential = await _auth.signInWithCredential(credential);
    await _markUserActive(userCredential.user?.uid);

    return userCredential;
  }

  /// Marks the user active in Firestore, and stamps `joinedAt` only the
  /// first time this doc is ever created (so repeat logins don't reset it).
  Future<void> _markUserActive(String? uid) async {
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final existing = await docRef.get();

    await docRef.set({
      'isActive': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marks the user inactive in Firestore, then signs them out of
  /// Firebase Auth.
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isActive': false,
      });
    }
    await _auth.signOut();
  }
}