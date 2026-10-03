import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/config/feature_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../notifications/data/push_notification_service.dart';
import '../../notifications/data/push_token_registrar.dart';
import '../application/device_auth_controller.dart';
import '../application/locale_controller.dart';
import '../application/theme_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _deviceAuthBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(appFeaturesProvider).pushNotificationsEnabled) {
      ref.invalidate(pushNotificationAuthorizationProvider);
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    try {
      await ref.read(themeModeProvider.notifier).setMode(mode);
    } catch (_) {
      if (mounted) {
        showMessage(context, AppLocalizations.of(context).saveFailed);
      }
    }
  }

  Future<void> _setLocale(Locale? locale) async {
    try {
      await ref.read(localeProvider.notifier).setLocale(locale);
    } catch (_) {
      if (mounted) {
        showMessage(context, AppLocalizations.of(context).saveFailed);
      }
    }
  }

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
    final features = ref.watch(appFeaturesProvider);
    final l10n = AppLocalizations.of(context);
    final deviceAuthEnabled = features.deviceAuthenticationEnabled
        ? ref.watch(deviceAuthEnabledProvider)
        : false;
    final mode = features.appearanceSettingsEnabled
        ? ref.watch(themeModeProvider)
        : ThemeMode.system;
    final locale = features.languageSettingsEnabled
        ? ref.watch(localeProvider)
        : null;
    final selectedLanguageCode = locale?.languageCode ?? 'system';
    final hasNonNotificationSettings =
        features.deviceAuthenticationEnabled ||
        features.appearanceSettingsEnabled ||
        features.languageSettingsEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (features.deviceAuthenticationEnabled)
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.phonelink_lock_outlined),
                title: Text(l10n.deviceAuthTitle),
                subtitle: Text(l10n.deviceAuthDescription),
                value: deviceAuthEnabled,
                onChanged: _deviceAuthBusy ? null : _setDeviceAuth,
              ),
            ),
          if (features.deviceAuthenticationEnabled &&
              features.appearanceSettingsEnabled)
            const SizedBox(height: AppSpacing.md),
          if (features.appearanceSettingsEnabled)
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
                          _setTheme(selection);
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
          if (features.appearanceSettingsEnabled &&
              features.languageSettingsEnabled)
            const SizedBox(height: AppSpacing.md),
          if (features.languageSettingsEnabled)
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
                        _setLocale(code == 'system' ? null : Locale(code));
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
          if (features.pushNotificationsEnabled) ...[
            if (hasNonNotificationSettings)
              const SizedBox(height: AppSpacing.md),
            const PushNotificationsSettingsCard(),
          ],
        ],
      ),
    );
  }
}

class PushNotificationsSettingsCard extends ConsumerWidget {
  const PushNotificationsSettingsCard({super.key});

  Future<void> _requestPermission(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pushNotificationClientProvider).requestPermission();
      ref.invalidate(pushNotificationAuthorizationProvider);
      await ref.read(pushTokenRegistrarProvider).syncForCurrentUser();
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          AppLocalizations.of(context).notificationsRequestFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authorization = ref.watch(pushNotificationAuthorizationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notificationsTitle),
              subtitle: authorization.when(
                data: (status) => Text(switch (status) {
                  PushAuthorizationStatus.authorized ||
                  PushAuthorizationStatus.provisional =>
                    l10n.notificationsEnabled,
                  PushAuthorizationStatus.denied => l10n.notificationsDenied,
                  PushAuthorizationStatus.notDetermined =>
                    l10n.notificationsNotEnabled,
                }),
                error: (_, _) => Text(l10n.notificationsStatusFailed),
                loading: () => const LinearProgressIndicator(),
              ),
            ),
            authorization.when(
              data: (status) {
                if (status == PushAuthorizationStatus.notDetermined) {
                  return Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      onPressed: () => _requestPermission(context, ref),
                      child: Text(l10n.notificationsEnable),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              error: (_, _) => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: l10n.retry,
                  onPressed: () =>
                      ref.invalidate(pushNotificationAuthorizationProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              loading: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
