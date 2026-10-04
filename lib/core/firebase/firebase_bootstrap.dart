import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../config/feature_config.dart';
import '../config/app_config.dart';
import '../../firebase_options.dart';

/// Initializes Firebase and wires global error handling.
/// Crash reports are sent only when the Crash Reporting module is enabled
/// and the app is running in release mode.
Future<void> bootstrapFirebase(AppFeatures features) async {
  if (!features.firebaseEnabled) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    final isDebug = kDebugMode || AppConfig.firebaseEmulatorHost.isNotEmpty;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: isDebug
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: isDebug
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  final emulatorHost = AppConfig.firebaseEmulatorHost;
  if (emulatorHost.isNotEmpty) {
    FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
    FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).useFunctionsEmulator(emulatorHost, 5001);
  }

  final report = features.crashReporting && kReleaseMode && !kIsWeb;

  FlutterError.onError = (details) {
    if (report) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (report) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('Unhandled error: $error\n$stack');
    }
    return true;
  };
}
