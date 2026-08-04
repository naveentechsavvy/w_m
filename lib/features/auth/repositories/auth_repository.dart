import '../datasources/auth_datasource.dart';

class AuthRepository {
  final AuthDataSource datasource = AuthDataSource();

  Future<void> verifyPhone({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) failed,
  }) {
    return datasource.verifyPhone(
      phoneNumber: phone,
      codeSent: codeSent,
      failed: failed,
    );
  }

  Future verifyOtp({
    required String verificationId,
    required String otp,
  }) {
    return datasource.verifyOtp(
      verificationId: verificationId,
      otp: otp,
    );
  }
}