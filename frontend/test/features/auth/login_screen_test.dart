import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/presentation/login_screen.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

Future<Widget> _wrap(
  FakeAuthRepository fake, {
  Locale locale = const Locale('en'),
  Map<String, Object> preferences = const {},
  AppFeatures features = const AppFeatures(),
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      sharedPreferencesProvider.overrideWithValue(prefs),
      appFeaturesProvider.overrideWithValue(features),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
    ),
  );
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

bool _checked(WidgetTester tester) =>
    tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value!;

void main() {
  testWidgets('shows validation errors when the form is empty', (tester) async {
    await tester.pumpWidget(await _wrap(FakeAuthRepository()));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('submits valid credentials to the repository', (tester) async {
    final fake = FakeAuthRepository();
    await tester.pumpWidget(await _wrap(fake));

    await _signIn(tester, 'user@example.com', '123456');

    expect(fake.lastEmail, 'user@example.com');
  });

  testWidgets('shows a friendly message when sign in fails', (tester) async {
    final fake = FakeAuthRepository()..shouldFail = true;
    await tester.pumpWidget(await _wrap(fake));

    await _signIn(tester, 'user@example.com', 'badpass');

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('renders in French when the locale is fr', (tester) async {
    await tester.pumpWidget(
      await _wrap(FakeAuthRepository(), locale: const Locale('fr')),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Se souvenir de mon e-mail'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  group('remember email', () {
    testWidgets('starts unchecked and empty when nothing is remembered', (
      tester,
    ) async {
      await tester.pumpWidget(await _wrap(FakeAuthRepository()));

      expect(find.text('Remember my email'), findsOneWidget);
      expect(_checked(tester), isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
    });

    testWidgets('prefills the remembered email and keeps the box checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _wrap(
          FakeAuthRepository(),
          preferences: {'remembered_email': 'saved@example.com'},
        ),
      );

      expect(find.text('saved@example.com'), findsOneWidget);
      expect(_checked(tester), isTrue);
    });

    testWidgets('remembers the email after a successful sign in', (
      tester,
    ) async {
      await tester.pumpWidget(await _wrap(FakeAuthRepository()));

      await tester.tap(find.text('Remember my email'));
      await tester.pump();
      await _signIn(tester, ' user@example.com ', '123456');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('remembered_email'), 'user@example.com');
    });

    testWidgets('forgets the email when signing in with the box unchecked', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _wrap(
          FakeAuthRepository(),
          preferences: {'remembered_email': 'saved@example.com'},
        ),
      );

      await tester.tap(find.text('Remember my email'));
      await tester.pump();
      await _signIn(tester, 'saved@example.com', '123456');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('remembered_email'), isNull);
    });

    testWidgets('does not remember the email when sign in fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _wrap(FakeAuthRepository()..shouldFail = true),
      );

      await tester.tap(find.text('Remember my email'));
      await tester.pump();
      await _signIn(tester, 'user@example.com', 'badpass');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('remembered_email'), isNull);
    });

    testWidgets('is hidden and ignored when the module is off', (tester) async {
      await tester.pumpWidget(
        await _wrap(
          FakeAuthRepository(),
          preferences: {'remembered_email': 'saved@example.com'},
          features: const AppFeatures(rememberEmail: false),
        ),
      );

      expect(find.text('Remember my email'), findsNothing);
      expect(find.text('saved@example.com'), findsNothing);
    });
  });
}
