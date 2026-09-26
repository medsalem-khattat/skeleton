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

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (shouldFail) throw FirebaseAuthException(code: 'wrong-password');
    lastEmail = email;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw FirebaseAuthException(code: 'email-already-in-use');
    lastEmail = email;
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
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  User? get currentUser => null;
}
