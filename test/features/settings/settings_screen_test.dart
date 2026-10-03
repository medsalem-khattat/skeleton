import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/config/feature_providers.dart';
import 'package:skeleton/features/auth/application/auth_providers.dart';
import 'package:skeleton/features/settings/presentation/account_security_screen.dart';
import 'package:skeleton/features/notifications/data/push_notification_service.dart';
import 'package:skeleton/features/notifications/data/notification_preferences.dart';
import 'package:skeleton/features/notifications/data/push_token_registrar.dart';
import 'package:skeleton/features/settings/application/device_auth_controller.dart';
import 'package:skeleton/features/settings/application/theme_controller.dart';
import 'package:skeleton/features/settings/presentation/settings_screen.dart';
import 'package:skeleton/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('notification preference is saved for the signed-in user', (
    tester,
  ) async {
    final preferences = _FakeNotificationPreferencesRepository();
    final registrar = _FakePushTokenRegistrar();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signedInUserIdProvider.overrideWithValue('user-1'),
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: true,
              home: true,
              settings: true,
              appearanceSettings: false,
              languageSettings: false,
              deviceAuthentication: false,
              pushNotifications: true,
              crashReporting: false,
            ),
          ),
          notificationPreferencesRepositoryProvider.overrideWithValue(
            preferences,
          ),
          pushTokenRegistrarProvider.overrideWithValue(registrar),
          pushNotificationClientProvider.overrideWithValue(
            _FakePushNotificationClient()
              ..status = PushAuthorizationStatus.authorized,
          ),
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
      find.text('This account can send push notifications to your devices.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(preferences.lastUserId, 'user-1');
    expect(preferences.enabled, isFalse);
    expect(registrar.syncCount, 0);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(preferences.enabled, isTrue);
    expect(registrar.syncCount, 1);
  });

  testWidgets('appearance and language open compact selection sheets', (
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
              settings: true,
              deviceAuthentication: false,
              pushNotifications: false,
              crashReporting: false,
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System'), findsNWidgets(2));
    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);
    expect(find.text('English'), findsNothing);
    expect(find.text('French'), findsNothing);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(preferences.getString('theme_mode'), 'dark');
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('French'), findsOneWidget);
    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(preferences.getString('locale'), 'fr');
  });

  testWidgets('opens Account & security from Settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appFeaturesProvider.overrideWithValue(
            const AppFeatures(
              authentication: true,
              home: true,
              profile: true,
              settings: true,
              appearanceSettings: false,
              languageSettings: false,
              deviceAuthentication: true,
              pushNotifications: false,
              crashReporting: false,
            ),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Manage sign-in details and app lock.'), findsOneWidget);
    await tester.tap(find.text('Account security'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSecurityScreen), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Change email'), findsOneWidget);
    expect(find.text('Change mobile number'), findsOneWidget);
  });

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
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
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

    await tester.tap(find.text('Account security'));
    await tester.pumpAndSettle();
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

    expect(
      find.text('Autorisation de notification de l’appareil'),
      findsOneWidget,
    );
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

class _FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  bool enabled = true;
  String? lastUserId;

  @override
  Stream<bool> watchEnabled(String userId) => Stream.value(enabled);

  @override
  Future<void> setEnabled(String userId, bool value) async {
    lastUserId = userId;
    enabled = value;
  }
}

class _FakePushTokenRegistrar implements PushTokenRegistrarClient {
  int syncCount = 0;

  @override
  Future<void> syncForCurrentUser() async {
    syncCount++;
  }

  @override
  Future<void> unregisterCurrentToken() async {}
}
