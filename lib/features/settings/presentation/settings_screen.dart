import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../application/device_auth_controller.dart';
import '../application/locale_controller.dart';
import '../application/theme_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deviceAuthBusy = false;

  Future<void> _setDeviceAuth(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _deviceAuthBusy = true);
    try {
      final authenticator = ref.read(deviceAuthenticatorProvider);
      if (!await authenticator.isDeviceSupported()) {
        if (mounted) showMessage(context, l10n.deviceAuthUnavailable);
        return;
      }

      final authenticated = await authenticator.authenticate(
        l10n.deviceAuthReason,
      );
      if (!mounted) return;
      if (!authenticated) {
        showMessage(context, l10n.deviceAuthFailed);
        return;
      }

      await ref.read(deviceAuthEnabledProvider.notifier).setEnabled(enabled);
    } on LocalAuthException {
      if (mounted) showMessage(context, l10n.deviceAuthFailed);
    } catch (_) {
      if (mounted) showMessage(context, l10n.deviceAuthSaveFailed);
    } finally {
      if (mounted) setState(() => _deviceAuthBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceAuthEnabled = ref.watch(deviceAuthEnabledProvider);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final selectedLanguageCode = locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.phonelink_lock_outlined),
              title: Text(l10n.deviceAuthTitle),
              subtitle: Text(l10n.deviceAuthDescription),
              value: deviceAuthEnabled,
              onChanged: _deviceAuthBusy ? null : _setDeviceAuth,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
