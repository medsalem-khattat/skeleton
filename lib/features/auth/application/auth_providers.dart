import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// Emits the signed-in user, or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Runs auth actions and exposes loading / error state to the UI.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> register(String name, String email, String password) =>
      _run(() => _repo.register(name: name, email: email, password: password));

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run(
    () => _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  Future<bool> verifyEmailChange({
    required String currentPassword,
    required String newEmail,
  }) => _run(
    () => _repo.verifyEmailChange(
      currentPassword: currentPassword,
      newEmail: newEmail,
    ),
  );

  Future<bool> signOut() => _run(_repo.signOut);
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
