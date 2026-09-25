import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/firestore_retry.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../l10n/app_localizations.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    try {
      await user.updateDisplayName(name.trim());
      await firestoreRetry(
        () => _db.collection(AppConfig.usersCollection).doc(user.uid).set({
          'name': name.trim(),
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
    } catch (error) {
      Object? signOutError;
      try {
        await signOut();
      } catch (cleanupError) {
        signOutError = cleanupError;
      }
      throw AccountProfileSetupException(error, signOutError: signOutError);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    // Clears any sensitive values the app may have cached locally,
    // so a storage failure does not happen after authentication has ended.
    await SecureStorage.clearAll();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}

class AccountProfileSetupException implements Exception {
  const AccountProfileSetupException(this.cause, {this.signOutError});

  final Object cause;
  final Object? signOutError;
}

/// Turns any error into a localized message that is safe to show to the user.
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (error is AccountProfileSetupException) {
    return l10n.accountSetupFailed;
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return l10n.errorInvalidEmail;
      case 'user-disabled':
        return l10n.errorUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.errorWrongCredentials;
      case 'email-already-in-use':
        return l10n.errorEmailInUse;
      case 'weak-password':
        return l10n.errorWeakPassword;
      case 'network-request-failed':
        return l10n.errorNetwork;
      case 'too-many-requests':
        return l10n.errorTooManyAttempts;
      default:
        return l10n.errorUnknownCode(error.code);
    }
  }
  return l10n.errorGeneric;
}
