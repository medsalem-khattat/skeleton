import 'package:firebase_auth/firebase_auth.dart';
import 'package:skeleton/features/auth/data/auth_repository.dart';

/// In-memory stand-in for AuthRepository so tests never touch Firebase.
class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String? lastEmail;
  int signOutCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastNewEmail;
  int verificationEmailSendCount = 0;
  int verificationStatusCheckCount = 0;
  bool emailVerified = false;
  String? lastPhoneNumber;
  String? lastSmsCode;
  String? lastVerificationId;
  String? lastRegisteredName;
  String? lastPhoneVerificationId;
  String? lastPhoneSmsCode;
  PhoneAuthCredential? lastPhoneCredential;
  int? lastResendToken;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (shouldFail) throw FirebaseAuthException(code: 'wrong-password');
    lastEmail = email;
  }

  @override
  Future<PhoneVerificationResult> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
  }) async {
    if (shouldFail) throw FirebaseAuthException(code: 'invalid-phone-number');
    lastPhoneNumber = phoneNumber;
    lastResendToken = forceResendingToken;
    return const PhoneVerificationResult.codeSent(
      verificationId: 'test-verification-id',
      resendToken: 42,
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required PhoneAuthCredential? phoneCredential,
    required String? verificationId,
    required String? smsCode,
  }) async {
    if (shouldFail) throw FirebaseAuthException(code: 'email-already-in-use');
    lastRegisteredName = name;
    lastEmail = email;
    lastVerificationId = verificationId;
    lastSmsCode = smsCode;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (shouldFail) throw FirebaseAuthException(code: 'user-not-found');
    lastEmail = email;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (shouldFail) throw FirebaseAuthException(code: 'network-request-failed');
    verificationEmailSendCount++;
  }

  @override
  Future<bool> reloadEmailVerification() async {
    verificationStatusCheckCount++;
    return emailVerified;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldFail) throw FirebaseAuthException(code: 'wrong-password');
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }

  @override
  Future<void> verifyEmailChange({
    required String currentPassword,
    required String newEmail,
  }) async {
    if (shouldFail) throw FirebaseAuthException(code: 'wrong-password');
    lastCurrentPassword = currentPassword;
    lastNewEmail = newEmail;
  }

  @override
  Future<void> updatePhoneNumber({
    required String currentPassword,
    required PhoneAuthCredential? phoneCredential,
    required String? verificationId,
    required String? smsCode,
  }) async {
    if (shouldFail) {
      throw FirebaseAuthException(code: 'invalid-verification-code');
    }
    lastCurrentPassword = currentPassword;
    lastPhoneCredential = phoneCredential;
    lastPhoneVerificationId = verificationId;
    lastPhoneSmsCode = smsCode;
  }

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  User? get currentUser => null;
}
