import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skeleton/core/router/app_routes.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/presentation/verify_email_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('shows verification guidance and supports resending', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VerifyEmailScreen(),
        ),
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('I have verified my email'), findsNothing);
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(repository.verificationEmailSendCount, 1);
    expect(
      find.text('Verification email sent. Check your inbox and spam folder.'),
      findsOneWidget,
    );
  });

  testWidgets('automatically opens the app after email verification', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final router = GoRouter(
      initialLocation: AppRoutes.verifyEmail,
      routes: [
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.verificationStatusCheckCount, greaterThan(0));
    expect(find.text('Verify your email'), findsOneWidget);

    repository.emailVerified = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    router.dispose();
  });
}
