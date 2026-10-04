import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/core/router/app_router.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('first-run onboarding can be skipped and is remembered', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appFeaturesProvider.overrideWithValue(
          const AppFeatures(
            authentication: false,
            home: true,
            settings: false,
            pushNotifications: false,
            crashReporting: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A clearer place to get started'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(preferences.getBool('onboarding_completed'), isTrue);
  });
}
