import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/features/notifications/data/push_notification_service.dart';
import 'package:skeleton/features/settings/application/device_auth_controller.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/features/settings/presentation/settings_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

void main() {
  testWidgets('requests push notification permission from Settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final notifications = _FakePushNotificationClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: false,
              home: true,
              profile: false,
              settings: false,
              appearanceSettings: false,
              languageSettings: false,
              deviceAuthentication: false,
              pushNotifications: true,
              crashReporting: false,
            ),
          ),
          deviceAuthenticatorProvider.overrideWithValue(
            _FakeDeviceAuthenticator(),
          ),
          pushNotificationClientProvider.overrideWithValue(notifications),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Allow notifications to receive updates.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Enable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequestCount, 1);
    expect(find.text('Notifications are enabled.'), findsOneWidget);
  });

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
          pushNotificationClientProvider.overrideWithValue(
            _FakePushNotificationClient(),
          ),
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
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: false,
              home: true,
              profile: false,
              settings: false,
              appearanceSettings: false,
              languageSettings: false,
              deviceAuthentication: false,
              pushNotifications: true,
              crashReporting: false,
            ),
          ),
          pushNotificationClientProvider.overrideWithValue(
            _FakePushNotificationClient(),
          ),
        ],
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

    expect(find.text('Notifications push'), findsOneWidget);
    expect(
      find.text('Autorisez les notifications pour recevoir des mises à jour.'),
      findsOneWidget,
    );
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

class _FakePushNotificationClient implements PushNotificationClient {
  int permissionRequestCount = 0;
  PushAuthorizationStatus status = PushAuthorizationStatus.notDetermined;

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async => status;

  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    permissionRequestCount++;
    status = PushAuthorizationStatus.authorized;
    return status;
  }

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<NotificationTap> get notificationTaps => const Stream.empty();

  @override
  NotificationTap? takeInitialNotificationTap() => null;
}
