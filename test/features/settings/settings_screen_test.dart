import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/features/settings/application/device_auth_controller.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/features/settings/presentation/settings_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('enables device authentication after device confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final authenticator = _FakeDeviceAuthenticator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          deviceAuthenticatorProvider.overrideWithValue(authenticator),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(authenticator.authenticationCount, 1);
    expect(preferences.getBool('device_auth_enabled'), isTrue);
  });

  testWidgets('settings fit a narrow screen with French and large text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.5),
            ),
            child: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Sombre'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeDeviceAuthenticator implements DeviceAuthenticator {
  int authenticationCount = 0;

  @override
  Future<bool> authenticate(String localizedReason) async {
    authenticationCount++;
    return true;
  }

  @override
  Future<bool> isDeviceSupported() async => true;
}
