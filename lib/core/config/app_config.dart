import 'package:flutter/material.dart';

/// Central config: the ONLY file to edit after cloning the skeleton.
/// Secrets are NOT stored here. They are injected at build time with
/// --dart-define (Codemagic / GitHub Actions secrets).
class AppConfig {
  AppConfig._();

  // --- Identity (edit per clone) ---
  static const String appName = 'Skeleton';
  static const String bundleId = 'com.medsalem.skeleton';
  static const String supportEmail = 'support@example.com';
  static const String appVersion = '1.0.0';

  // --- Firebase (details live in firebase_options.dart,
  //     regenerated with `flutterfire configure` per clone) ---
  static const String firebaseProjectId = 'skeleton-d295d';
  static const String usersCollection = 'users';

  // --- Design (edit per clone: this single seed drives the whole
  //     light/dark ColorScheme via Material 3) ---
  static const Color seedColor = Color(0xFF3F51B5);

  // --- Secrets: injected at build time, never committed ---
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String apiKey =
      String.fromEnvironment('API_KEY', defaultValue: '');

  // --- Feature flags (turn template features on/off per clone) ---
  static const bool enableBiometricLogin = false;
  static const bool enablePushNotifications = false;
}
