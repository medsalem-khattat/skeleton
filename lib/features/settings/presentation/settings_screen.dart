import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../application/locale_controller.dart';
import '../application/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOutQuestion),
        content: Text(l10n.logOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // The router redirects to the login screen once signed out.
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final languageValue = locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Text(l10n.appearance),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) => ref
                  .read(themeModeProvider.notifier)
                  .setMode(selection.first),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
            child: Text(l10n.language),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', label: Text(l10n.languageSystem)),
                const ButtonSegment(value: 'en', label: Text('English')),
                const ButtonSegment(value: 'fr', label: Text('Français')),
              ],
              selected: {languageValue},
              onSelectionChanged: (selection) {
                final code = selection.first;
                ref
                    .read(localeProvider.notifier)
                    .setLocale(code == 'system' ? null : Locale(code));
              },
            ),
          ),
          SizedBox(height: AppSpacing.md),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            trailing: const Text(AppConfig.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logOut),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
