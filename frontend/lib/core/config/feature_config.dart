import '../router/app_routes.dart';

/// Compile-time switches for the app's independently selectable modules.
///
/// [AppFeatures.current] is set per deployment by the `features` section of
/// `deployments/<id>/deployment.json` (compiled in as `FEATURE_*` defines).
/// Profile, notification inbox, and device authentication require
/// Authentication; dependent modules are considered disabled when
/// Authentication is off. When adding a module, define its dependency rules
/// here and in `tool/deployment.mjs`, and cover valid and invalid
/// combinations in `test/core/config/feature_config_test.dart`.
class AppFeatures {
  const AppFeatures({
    this.authentication = true,
    this.phoneVerification = true,
    this.home = true,
    this.profile = true,
    this.settings = true,
    this.appearanceSettings = true,
    this.languageSettings = true,
    this.deviceAuthentication = true,
    this.pushNotifications = true,
    this.notificationInbox = true,
    this.crashReporting = true,
  });

  static const current = AppFeatures(
    authentication: bool.fromEnvironment(
      'FEATURE_AUTHENTICATION',
      defaultValue: true,
    ),
    phoneVerification: bool.fromEnvironment(
      'FEATURE_PHONE_VERIFICATION',
      defaultValue: true,
    ),
    home: bool.fromEnvironment('FEATURE_HOME', defaultValue: true),
    profile: bool.fromEnvironment('FEATURE_PROFILE', defaultValue: true),
    settings: bool.fromEnvironment('FEATURE_SETTINGS', defaultValue: true),
    appearanceSettings: bool.fromEnvironment(
      'FEATURE_APPEARANCE_SETTINGS',
      defaultValue: true,
    ),
    languageSettings: bool.fromEnvironment(
      'FEATURE_LANGUAGE_SETTINGS',
      defaultValue: true,
    ),
    deviceAuthentication: bool.fromEnvironment(
      'FEATURE_DEVICE_AUTHENTICATION',
      defaultValue: true,
    ),
    pushNotifications: bool.fromEnvironment(
      'FEATURE_PUSH_NOTIFICATIONS',
      defaultValue: true,
    ),
    notificationInbox: bool.fromEnvironment(
      'FEATURE_NOTIFICATION_INBOX',
      defaultValue: true,
    ),
    crashReporting: bool.fromEnvironment(
      'FEATURE_CRASH_REPORTING',
      defaultValue: true,
    ),
  );

  final bool authentication;

  /// Registration requires an SMS-verified phone number, and users can change
  /// it in Account security. Firebase phone sign-in needs the Blaze plan.
  final bool phoneVerification;
  final bool home;
  final bool profile;
  final bool settings;
  final bool appearanceSettings;
  final bool languageSettings;
  final bool deviceAuthentication;
  final bool pushNotifications;
  final bool notificationInbox;
  final bool crashReporting;

  bool get phoneVerificationEnabled => authentication && phoneVerification;

  bool get profileEnabled => authentication && profile;

  bool get deviceAuthenticationEnabled =>
      authentication && settings && deviceAuthentication;

  bool get pushNotificationsEnabled => pushNotifications;

  bool get notificationInboxEnabled => authentication && notificationInbox;

  bool get appearanceSettingsEnabled => settings && appearanceSettings;

  bool get languageSettingsEnabled => settings && languageSettings;

  bool get settingsEnabled =>
      accountSecurityEnabled ||
      appearanceSettingsEnabled ||
      languageSettingsEnabled ||
      deviceAuthenticationEnabled ||
      pushNotificationsEnabled;

  bool get accountSecurityEnabled => authentication && settings;

  bool get firebaseEnabled =>
      authentication || crashReporting || pushNotificationsEnabled;

  String get authenticatedLocation {
    if (home) return AppRoutes.home;
    if (profileEnabled) return AppRoutes.profile;
    if (notificationInboxEnabled) return AppRoutes.notifications;
    if (settingsEnabled) return AppRoutes.settings;
    return AppRoutes.login;
  }

  String get initialLocation {
    if (authentication) {
      if (home) return AppRoutes.home;
      if (profileEnabled) return AppRoutes.profile;
      if (notificationInboxEnabled) return AppRoutes.notifications;
      if (settingsEnabled) return AppRoutes.settings;
      return AppRoutes.login;
    }
    if (home) return AppRoutes.home;
    if (settingsEnabled) return AppRoutes.settings;
    throw StateError(
      'Enable Home or at least one Settings module when Authentication is off.',
    );
  }

  /// Fails early for configurations that can authenticate but have nowhere
  /// to send a successfully signed-in user.
  void validate() {
    if (authentication &&
        !home &&
        !profileEnabled &&
        !notificationInboxEnabled &&
        !settingsEnabled) {
      throw StateError(
        'Enable Home, Profile, Notification Inbox, or at least one Settings '
        'module when Authentication is enabled.',
      );
    }
    if (!authentication && !home && !settingsEnabled) {
      throw StateError(
        'Enable Home or at least one Settings module when Authentication '
        'is disabled.',
      );
    }
  }
}
