import 'package:firebase_auth/firebase_auth.dart';
import 'package:skeleton/features/auth/data/auth_repository.dart';

/// In-memory stand-in for AuthRepository so tests never touch Firebase.
class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String? lastEmail;
  int signOutCalls = 0;

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
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  User? get currentUser => null;
}
