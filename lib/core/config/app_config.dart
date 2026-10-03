import 'package:flutter/material.dart';

import 'feature_config.dart';

/// Central config for project identity and build-time settings.
/// Feature modules are configured in feature_config.dart. Secrets are NOT
/// stored here; they are injected at build time with --dart-define.
class AppConfig {
  AppConfig._();

  // --- Identity (edit per clone) ---
  // NOTE: bundleId here is documentation only - the values that actually
  // matter are in android/app/build.gradle (applicationId) and the iOS
  // Xcode project. Keep this in sync with those, and with whatever
  // `flutterfire configure` reports.
  static const String appName = 'Skeleton';
  static const String bundleId = 'com.yourname.skeleton';
  static const String supportEmail = 'support@example.com';
  static const String appVersion = '1.0.0';

  // --- Firebase (details live in firebase_options.dart,
  //     regenerated with `flutterfire configure` per clone) ---
  static const String firebaseProjectId = 'whatsapp-bot-f57a8';
  static const String usersCollection = 'users';

  // --- Design (edit per clone: this single seed drives the whole
  //     light/dark ColorScheme via Material 3) ---
  static const Color seedColor = Color(0xFF3F51B5);

  // --- Secrets: injected at build time, never committed ---
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  // --- Feature modules (edit only feature_config.dart to toggle modules) ---
  static const AppFeatures features = AppFeatures.current;
}
