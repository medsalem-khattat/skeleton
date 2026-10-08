import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/presentation/register_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('requires phone verification before account creation', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repository));

    final createAccount = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(
      find.text('Verify your phone number before creating your account.'),
      findsOneWidget,
    );
    expect(repository.lastEmail, isNull);
  });

  testWidgets('registers email account with SMS verification proof', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrap(repository));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number'),
      '+1 415 555 2671',
    );
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    expect(repository.lastPhoneNumber, '+14155552671');
    expect(find.text('SMS verification code'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Test User',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'SMS verification code'),
      '123456',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(repository.lastEmail, 'user@example.com');
    expect(repository.lastVerificationId, 'test-verification-id');
    expect(repository.lastSmsCode, '123456');
  });
}

Widget _wrap(FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RegisterScreen(),
    ),
  );
}
