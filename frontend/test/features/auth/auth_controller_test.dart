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

  test('requests a phone verification code', () async {
    final challenge = await container
        .read(authControllerProvider.notifier)
        .sendPhoneVerificationCode(phoneNumber: '+14155552671');

    expect(challenge?.verificationId, 'test-verification-id');
    expect(fake.lastPhoneNumber, '+14155552671');
    expect(fake.lastResendToken, isNull);
  });

  test(
    'resends a phone verification code with Firebase resend token',
    () async {
      final challenge = await container
          .read(authControllerProvider.notifier)
          .sendPhoneVerificationCode(
            phoneNumber: '+14155552671',
            forceResendingToken: 42,
          );

      expect(challenge?.verificationId, 'test-verification-id');
      expect(fake.lastResendToken, 42);
    },
  );

  test('registration carries SMS proof to the repository', () async {
    final ok = await container
        .read(authControllerProvider.notifier)
        .register(
          name: 'Test User',
          email: 'a@b.com',
          password: 'password',
          phoneCredential: null,
          verificationId: 'test-verification-id',
          smsCode: '123456',
        );

    expect(ok, isTrue);
    expect(fake.lastRegisteredName, 'Test User');
    expect(fake.lastVerificationId, 'test-verification-id');
    expect(fake.lastSmsCode, '123456');
  });

  test('signOut calls the repository', () async {
    await container.read(authControllerProvider.notifier).signOut();
    expect(fake.signOutCalls, 1);
  });

  test('resendEmailVerification requests another verification email', () async {
    final sent = await container
        .read(authControllerProvider.notifier)
        .resendEmailVerification();

    expect(sent, isTrue);
    expect(fake.verificationEmailSendCount, 1);
  });

  test('reloadEmailVerification returns the refreshed status', () async {
    fake.emailVerified = true;

    final verified = await container
        .read(authControllerProvider.notifier)
        .reloadEmailVerification();

    expect(verified, isTrue);
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

  test('updatePhoneNumber forwards SMS verification proof', () async {
    final ok = await container
        .read(authControllerProvider.notifier)
        .updatePhoneNumber(
          currentPassword: 'current-pass',
          phoneCredential: null,
          verificationId: 'phone-verification-id',
          smsCode: '654321',
        );

    expect(ok, isTrue);
    expect(fake.lastCurrentPassword, 'current-pass');
    expect(fake.lastPhoneVerificationId, 'phone-verification-id');
    expect(fake.lastPhoneSmsCode, '654321');
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

    test('is translated', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(
        authErrorMessage(fr, FirebaseAuthException(code: 'wrong-password')),
        'E-mail ou mot de passe incorrect.',
      );
    });
  });
}
