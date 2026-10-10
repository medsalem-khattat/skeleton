import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/config/feature_config.dart';
import 'package:skeleton/core/router/app_routes.dart';

void main() {
  test('profile and device authentication depend on authentication', () {
    const features = AppFeatures(
      authentication: false,
      home: true,
      profile: true,
      settings: true,
      deviceAuthentication: true,
      pushNotifications: false,
      crashReporting: false,
    );

    expect(features.profileEnabled, isFalse);
    expect(features.deviceAuthenticationEnabled, isFalse);
    expect(features.firebaseEnabled, isFalse);
    expect(features.initialLocation, AppRoutes.home);
    expect(() => features.validate(), returnsNormally);
  });

  test('phone verification depends on authentication', () {
    expect(const AppFeatures().phoneVerificationEnabled, isTrue);
    expect(
      const AppFeatures(phoneVerification: false).phoneVerificationEnabled,
      isFalse,
    );
    expect(
      const AppFeatures(
        authentication: false,
        pushNotifications: false,
        crashReporting: false,
      ).phoneVerificationEnabled,
      isFalse,
    );
  });

  test('standalone language settings work without authentication', () {
    const features = AppFeatures(
      authentication: false,
      home: false,
      profile: true,
      settings: true,
      appearanceSettings: false,
      languageSettings: true,
      deviceAuthentication: true,
      pushNotifications: false,
      crashReporting: false,
    );

    expect(features.profileEnabled, isFalse);
    expect(features.deviceAuthenticationEnabled, isFalse);
    expect(features.settingsEnabled, isTrue);
    expect(features.initialLocation, AppRoutes.settings);
    expect(() => features.validate(), returnsNormally);
  });

  test('push notifications require Firebase and expose Settings', () {
    const features = AppFeatures(
      authentication: false,
      home: true,
      settings: false,
      pushNotifications: true,
      crashReporting: false,
    );

    expect(features.pushNotificationsEnabled, isTrue);
    expect(features.settingsEnabled, isTrue);
    expect(features.firebaseEnabled, isTrue);
  });

  test('notification inbox depends on Authentication', () {
    const authenticated = AppFeatures(
      authentication: true,
      home: false,
      profile: false,
      settings: false,
      notificationInbox: true,
      pushNotifications: false,
      crashReporting: false,
    );
    const anonymous = AppFeatures(
      authentication: false,
      home: true,
      notificationInbox: true,
      pushNotifications: false,
      crashReporting: false,
    );

    expect(authenticated.notificationInboxEnabled, isTrue);
    expect(authenticated.initialLocation, AppRoutes.notifications);
    expect(anonymous.notificationInboxEnabled, isFalse);
    expect(() => anonymous.validate(), returnsNormally);
  });

  test('rejects a configuration with no usable app screen', () {
    const features = AppFeatures(
      authentication: false,
      home: false,
      profile: true,
      settings: false,
      pushNotifications: false,
      crashReporting: false,
    );

    expect(features.profileEnabled, isFalse);
    expect(() => features.initialLocation, throwsStateError);
    expect(features.validate, throwsStateError);
  });

  test('rejects authentication without a post-login destination', () {
    const features = AppFeatures(
      authentication: true,
      home: false,
      profile: false,
      settings: false,
      notificationInbox: false,
      pushNotifications: false,
    );

    expect(features.validate, throwsStateError);
  });
}
