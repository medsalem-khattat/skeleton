import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_providers.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../notifications/data/push_token_registrar.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final pushEnabled = ref.watch(appFeaturesProvider).pushNotificationsEnabled;
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    beforeSignOut: pushEnabled
        ? () => ref.read(pushTokenRegistrarProvider).unregisterCurrentToken()
        : null,
  );
});

/// Emits the signed-in user, or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final signedInUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser?.uid;
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

  Future<PhoneVerificationResult?> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        onVerificationCompleted: onVerificationCompleted,
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required PhoneAuthCredential? phoneCredential,
    required String? verificationId,
    required String? smsCode,
  }) => _run(
    () => _repo.register(
      name: name,
      email: email,
      password: password,
      phoneCredential: phoneCredential,
      verificationId: verificationId,
      smsCode: smsCode,
    ),
  );

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<bool> resendEmailVerification() => _run(_repo.sendEmailVerification);

  Future<bool?> reloadEmailVerification() async {
    state = const AsyncLoading();
    try {
      final isVerified = await _repo.reloadEmailVerification();
      state = const AsyncData(null);
      return isVerified;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

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

  Future<bool> updatePhoneNumber({
    required String currentPassword,
    required PhoneAuthCredential? phoneCredential,
    required String? verificationId,
    required String? smsCode,
  }) => _run(
    () => _repo.updatePhoneNumber(
      currentPassword: currentPassword,
      phoneCredential: phoneCredential,
      verificationId: verificationId,
      smsCode: smsCode,
    ),
  );

  Future<bool> signOut() => _run(_repo.signOut);
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
