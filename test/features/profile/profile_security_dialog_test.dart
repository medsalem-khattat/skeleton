import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/profile/application/profile_providers.dart';
import 'package:skeleton/features/profile/data/user_profile.dart';
import 'package:skeleton/features/profile/presentation/profile_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('security dialogs dispose focused fields safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          profileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(name: 'Sam', email: 'sam@example.com'),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    final passwordField = find.byType(TextFormField).first;
    await tester.showKeyboard(passwordField);
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Change email'));
    await tester.pumpAndSettle();
    final emailField = find.byType(TextFormField).first;
    await tester.showKeyboard(emailField);
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
