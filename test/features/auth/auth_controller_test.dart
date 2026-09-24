import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/data/auth_repository.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fake;
  late ProviderContainer container;

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

  group('authErrorMessage', () {
    test('maps known Firebase codes to friendly messages', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect email or password.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        'An account already exists for this email.',
      );
    });

    test('falls back for unknown errors', () {
      expect(
        authErrorMessage(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
