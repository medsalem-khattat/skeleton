import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/features/home/presentation/home_screen.dart';
import 'package:skeleton/features/profile/application/profile_providers.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('shows shortcuts to existing profile and settings features', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) => Stream.value(null))],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('App preferences'), findsOneWidget);
    expect(find.text('Your app content goes here.'), findsNothing);
  });
}
