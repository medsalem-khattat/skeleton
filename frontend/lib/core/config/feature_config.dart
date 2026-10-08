import '../router/app_routes.dart';

/// Compile-time switches for the app's independently selectable modules.
///
/// Change [AppFeatures.current] to enable or disable modules. Profile,
/// notification inbox, and device authentication require Authentication;
/// dependent modules are considered disabled when Authentication is off.
/// When adding a module, define its dependency rules here and cover valid and
/// invalid combinations in `test/core/config/feature_config_test.dart`.
class AppFeatures {
  const AppFeatures({
    this.authentication = true,
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

  static const current = AppFeatures();

  final bool authentication;
  final bool home;
  final bool profile;
  final bool settings;
  final bool appearanceSettings;
  final bool languageSettings;
  final bool deviceAuthentication;
  final bool pushNotifications;
  final bool notificationInbox;
  final bool crashReporting;

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
