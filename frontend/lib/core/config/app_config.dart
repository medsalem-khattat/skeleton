import 'package:flutter/material.dart';

import 'feature_config.dart';

/// Deployment values, compiled in from `deployment.g.json`.
///
/// Edit `deployments/<id>/deployment.json`, never this file, then run
/// `node tool/deployment.mjs use <id>` and build with
/// `--dart-define-from-file=deployment.g.json`. The defaults below only apply
/// to builds without that file, such as `flutter test`.
///
/// Every value here ships inside the app and is therefore public. Never put a
/// secret in a deployment file or a --dart-define.
class AppConfig {
  AppConfig._();

  // --- Identity ---
  static const String deploymentId = String.fromEnvironment(
    'DEPLOYMENT_ID',
    defaultValue: 'unconfigured',
  );
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Skeleton',
  );

  /// Android application ID and iOS bundle ID; the native builds read the
  /// same value from the generated deployment files.
  static const String appId = String.fromEnvironment(
    'APP_ID',
    defaultValue: 'com.example.skeleton',
  );

  // --- Links ---
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: '',
  );
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: '',
  );
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: '',
  );
  static const String authActionContinueUrl = String.fromEnvironment(
    'AUTH_ACTION_CONTINUE_URL',
    defaultValue: '',
  );

  // --- Firebase: client options come from the deployment's generated
  //     firebase_options.dart. Local emulator use only: ---
  static const String firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '',
  );
  static const String usersCollection = 'users';

  /// Region of the deployment's Cloud Functions (`firebase.functionsRegion`).
  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  // --- Design: this single seed drives the light/dark Material 3 scheme ---
  static const Color seedColor = Color(
    int.fromEnvironment('SEED_COLOR', defaultValue: 0xFF3F51B5),
  );

  // --- Optional REST API ---
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Sent as `x-api-key`. It is compiled into the app, so it identifies the
  /// app to the API; it is not a secret and must not grant privileged access.
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  // --- Feature modules ---
  static const AppFeatures features = AppFeatures.current;
}
