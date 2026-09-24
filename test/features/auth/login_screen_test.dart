import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/auth/presentation/login_screen.dart';

import '../../helpers/fake_auth_repository.dart';

Widget _wrap(FakeAuthRepository fake) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(fake)],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('shows validation errors when the form is empty', (tester) async {
    await tester.pumpWidget(_wrap(FakeAuthRepository()));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('submits valid credentials to the repository', (tester) async {
    final fake = FakeAuthRepository();
    await tester.pumpWidget(_wrap(fake));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), '123456');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(fake.lastEmail, 'user@example.com');
  });

  testWidgets('shows a friendly message when sign in fails', (tester) async {
    final fake = FakeAuthRepository()..shouldFail = true;
    await tester.pumpWidget(_wrap(fake));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'badpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
