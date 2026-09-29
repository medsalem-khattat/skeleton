import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/core/auth/device_auth_gate.dart';
import 'package:skeleton/features/settings/application/device_auth_controller.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('locks verified sessions and unlocks after device auth', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'device_auth_enabled': true});
    final preferences = await SharedPreferences.getInstance();
    final authenticator = _FakeDeviceAuthenticator();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        deviceAuthenticatorProvider.overrideWithValue(authenticator),
        verifiedDeviceAuthSessionProvider.overrideWithValue('user-id'),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(deviceAuthEnabledProvider), isTrue);
    expect(container.read(verifiedDeviceAuthSessionProvider), 'user-id');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeviceAuthGate(child: Text('Protected content')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Unlock to continue'), findsOneWidget);
    expect(authenticator.authenticationCount, 1);

    authenticator.authenticationResult = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Protected content'), findsOneWidget);
  });
}

class _FakeDeviceAuthenticator implements DeviceAuthenticator {
  bool authenticationResult = false;
  int authenticationCount = 0;

  @override
  Future<bool> authenticate(String localizedReason) async {
    authenticationCount++;
    return authenticationResult;
  }

  @override
  Future<bool> isDeviceSupported() async => true;
}
