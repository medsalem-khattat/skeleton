import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/notifications/data/push_notification_service.dart';
import 'features/settings/application/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final features = AppConfig.features;
  features.validate();
  await bootstrapFirebase(features);
  final pushNotificationClient = features.pushNotificationsEnabled
      ? PushNotificationService()
      : null;
  if (pushNotificationClient != null) await pushNotificationClient.initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (pushNotificationClient != null)
          pushNotificationClientProvider.overrideWithValue(
            pushNotificationClient,
          ),
      ],
      child: const App(),
    ),
  );
}
