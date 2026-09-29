import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import 'theme_controller.dart';

/// The language chosen in Settings. `null` means "follow the device language".
class LocaleController extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    if (code == null) return null;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    late final bool saved;
    if (locale == null) {
      saved = await prefs.remove(_key);
    } else {
      saved = await prefs.setString(_key, locale.languageCode);
    }
    if (!saved) throw StateError('Language preference could not be saved.');
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
