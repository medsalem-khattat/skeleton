import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/feature_config.dart';
import '../../firebase_options.dart';

/// Initializes Firebase and wires global error handling.
/// Crash reports are sent only when the Crash Reporting module is enabled
/// and the app is running in release mode.
Future<void> bootstrapFirebase(AppFeatures features) async {
  if (!features.firebaseEnabled) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
