import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/data/auth_repository.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fake;
  late ProviderContainer container;
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUp(() {
    fake = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
  });

  test('signIn succeeds and returns true', () async {
    final ok = await container
        .read(authControllerProvider.notifier)
        .signIn('a@b.com', '123456');

    expect(ok, isTrue);
    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(fake.lastEmail, 'a@b.com');
  });

  test('signIn failure returns false and exposes the error', () async {
    fake.shouldFail = true;

    final ok = await container
        .read(authControllerProvider.notifier)
        .signIn('a@b.com', 'wrong-pass');

    expect(ok, isFalse);
    expect(container.read(authControllerProvider).hasError, isTrue);
  });

  test('signOut calls the repository', () async {
    await container.read(authControllerProvider.notifier).signOut();
    expect(fake.signOutCalls, 1);
  });

  test('changePassword forwards current and new passwords', () async {
    final ok = await container
        .read(authControllerProvider.notifier)
        .changePassword(currentPassword: 'old-pass', newPassword: 'new-pass');

    expect(ok, isTrue);
    expect(fake.lastCurrentPassword, 'old-pass');
    expect(fake.lastNewPassword, 'new-pass');
  });

  test('verifyEmailChange forwards the target email', () async {
    final ok = await container
        .read(authControllerProvider.notifier)
        .verifyEmailChange(
          currentPassword: 'current-pass',
          newEmail: 'new@example.com',
        );

    expect(ok, isTrue);
    expect(fake.lastCurrentPassword, 'current-pass');
    expect(fake.lastNewEmail, 'new@example.com');
  });

  group('authErrorMessage', () {
    test('maps known Firebase codes to friendly messages', () {
      expect(
        authErrorMessage(l10n, FirebaseAuthException(code: 'wrong-password')),
        'Incorrect email or password.',
      );
      expect(
        authErrorMessage(
          l10n,
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'An account already exists for this email.',
      );
    });

    test('includes the code for unknown Firebase errors', () {
      expect(
        authErrorMessage(l10n, FirebaseAuthException(code: 'weird-code')),
        'Something went wrong (weird-code).',
      );
    });

    test('falls back for non-Firebase errors', () {
      expect(
        authErrorMessage(l10n, Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });

    test('explains when account setup is incomplete', () {
      expect(
        authErrorMessage(
          l10n,
          AccountProfileSetupException(Exception('Firestore failed')),
        ),
        'Your account was created, but profile setup did not finish. '
        'Sign in and complete your profile.',
      );
    });

    test('is translated', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(
        authErrorMessage(fr, FirebaseAuthException(code: 'wrong-password')),
        'E-mail ou mot de passe incorrect.',
      );
    });
  });
}
