import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/storage/secure_storage.dart';

abstract interface class AccountAdminRepository {
  Future<void> deleteAccount({required String currentPassword});
  Future<void> signOutAllSessions({required String currentPassword});
}

class FirebaseAccountAdminRepository implements AccountAdminRepository {
  FirebaseAccountAdminRepository(this._auth, this._functions);

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    await _reauthenticate(currentPassword);
    await _functions.httpsCallable('deleteAccount').call<void>();
    await _clearLocalSession();
  }

  @override
  Future<void> signOutAllSessions({required String currentPassword}) async {
    await _reauthenticate(currentPassword);
    await _functions.httpsCallable('revokeAllSessions').call<void>();
    await _clearLocalSession();
  }

  Future<User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('An authenticated email/password user is required.');
    }
    final supportsPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!supportsPassword) {
      throw StateError('Password reauthentication is not available.');
    }

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    return user;
  }

  Future<void> _clearLocalSession() async {
    try {
      await SecureStorage.clearAll();
    } finally {
      await _auth.signOut();
    }
  }
}
