import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/core/router/app_router.dart';
import 'package:skeleton/core/router/app_routes.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('Home works without Firebase when Authentication is disabled', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appFeaturesProvider.overrideWithValue(
          const AppFeatures(
            authentication: false,
            home: true,
            profile: true,
            settings: false,
            pushNotifications: false,
            crashReporting: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);

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

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Log out'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });
}
