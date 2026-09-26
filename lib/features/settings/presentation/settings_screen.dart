import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/locale_controller.dart';
import '../application/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final selectedLanguageCode = locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appearance,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RadioGroup<ThemeMode>(
                    groupValue: mode,
                    onChanged: (selection) {
                      if (selection != null) {
                        ref.read(themeModeProvider.notifier).setMode(selection);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          title: Text(l10n.themeSystem),
                          secondary: const Icon(Icons.brightness_auto),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          title: Text(l10n.themeLight),
                          secondary: const Icon(Icons.light_mode),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          title: Text(l10n.themeDark),
                          secondary: const Icon(Icons.dark_mode),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: Text(
                    l10n.language,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RadioGroup<String>(
                  groupValue: selectedLanguageCode,
                  onChanged: (code) {
                    if (code != null) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(code == 'system' ? null : Locale(code));
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'system',
                        title: Text(l10n.languageSystem),
                      ),
                      const RadioListTile<String>(
                        value: 'en',
                        title: Text('English'),
                      ),
                      const RadioListTile<String>(
                        value: 'fr',
                        title: Text('Français'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
