import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/presentation/email_action_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('verifies email action codes and shows success', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EmailActionScreen(mode: 'verifyEmail', actionCode: 'verify-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.lastActionCode, 'verify-1');
    expect(find.text('Your email address is verified.'), findsOneWidget);
  });

  testWidgets('validates and applies an in-app password reset code', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EmailActionScreen(mode: 'resetPassword', actionCode: 'reset-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(auth.lastActionCode, 'reset-1');
    expect(auth.lastResetPassword, 'new-password');
    expect(find.text('Your password has been reset.'), findsOneWidget);
  });
}
