import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/device_auth_gate.dart';
import 'core/auth/session_guard.dart';
import 'core/config/app_config.dart';
import 'core/config/feature_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/locale_controller.dart';
import 'features/settings/application/theme_controller.dart';
import 'l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(appFeaturesProvider);
    final router = ref.watch(routerProvider);
    final themeMode = features.appearanceSettingsEnabled
        ? ref.watch(themeModeProvider)
        : ThemeMode.system;
    final locale = features.languageSettingsEnabled
        ? ref.watch(localeProvider)
        : null;
    final app = MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) =>
          DeviceAuthGate(child: child ?? const SizedBox.shrink()),
    );
    return features.authentication ? SessionGuard(child: app) : app;
  }
}
