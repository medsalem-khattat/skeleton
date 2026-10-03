import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/data/notification_preferences.dart';
import '../../notifications/data/push_notification_service.dart';
import '../../notifications/data/push_token_registrar.dart';
import 'account_security_screen.dart';
import '../application/locale_controller.dart';
import '../application/theme_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
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

  Future<void> _selectTheme(ThemeMode current, AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              mode: ThemeMode.system,
              selected: current,
              label: l10n.themeSystem,
            ),
            _ThemeOption(
              mode: ThemeMode.light,
              selected: current,
              label: l10n.themeLight,
            ),
            _ThemeOption(
              mode: ThemeMode.dark,
              selected: current,
              label: l10n.themeDark,
            ),
          ],
        ),
      ),
    );
    if (selected != null) await _setTheme(selected);
  }

  Future<void> _selectLanguage(
    String selectedCode,
    AppLocalizations l10n,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              code: 'system',
              selectedCode: selectedCode,
              label: l10n.languageSystem,
            ),
            _LanguageOption(
              code: 'en',
              selectedCode: selectedCode,
              label: l10n.languageEnglish,
            ),
            _LanguageOption(
              code: 'fr',
              selectedCode: selectedCode,
              label: l10n.languageFrench,
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _setLocale(selected == 'system' ? null : Locale(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(appFeaturesProvider);
    final l10n = AppLocalizations.of(context);
    final mode = features.appearanceSettingsEnabled
        ? ref.watch(themeModeProvider)
        : ThemeMode.system;
    final locale = features.languageSettingsEnabled
        ? ref.watch(localeProvider)
        : null;
    final selectedLanguageCode = locale?.languageCode ?? 'system';
    final hasNonNotificationSettings =
        features.accountSecurityEnabled ||
        features.appearanceSettingsEnabled ||
        features.languageSettingsEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (features.accountSecurityEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.security_outlined),
                title: Text(l10n.accountSecurity),
                subtitle: Text(l10n.accountSecurityDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountSecurityScreen(),
                    ),
                  );
                },
              ),
            ),
          if (features.accountSecurityEnabled &&
              (features.appearanceSettingsEnabled ||
                  features.languageSettingsEnabled))
            const SizedBox(height: AppSpacing.md),
          if (features.appearanceSettingsEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l10n.appearance),
                subtitle: Text(switch (mode) {
                  ThemeMode.system => l10n.themeSystem,
                  ThemeMode.light => l10n.themeLight,
                  ThemeMode.dark => l10n.themeDark,
                }),
                trailing: const Icon(Icons.expand_more),
                onTap: () => _selectTheme(mode, l10n),
              ),
            ),
          if (features.appearanceSettingsEnabled &&
              features.languageSettingsEnabled)
            const SizedBox(height: AppSpacing.md),
          if (features.languageSettingsEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(switch (selectedLanguageCode) {
                  'en' => l10n.languageEnglish,
                  'fr' => l10n.languageFrench,
                  _ => l10n.languageSystem,
                }),
                trailing: const Icon(Icons.expand_more),
                onTap: () => _selectLanguage(selectedLanguageCode, l10n),
              ),
            ),
          if (features.pushNotificationsEnabled) ...[
            if (hasNonNotificationSettings)
              const SizedBox(height: AppSpacing.md),
            PushNotificationsSettingsCard(
              showUserPreference: features.authentication,
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.label,
  });

  final ThemeMode mode;
  final ThemeMode selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: mode == selected ? const Icon(Icons.check) : null,
      onTap: () => Navigator.pop(context, mode),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.selectedCode,
    required this.label,
  });

  final String code;
  final String selectedCode;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: code == selectedCode ? const Icon(Icons.check) : null,
      onTap: () => Navigator.pop(context, code),
    );
  }
}

class PushNotificationsSettingsCard extends ConsumerWidget {
  const PushNotificationsSettingsCard({
    super.key,
    this.showUserPreference = true,
  });

  final bool showUserPreference;

  Future<void> _setUserPreference(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (enabled) {
        var status = await ref
            .read(pushNotificationClientProvider)
            .authorizationStatus();
        if (status == PushAuthorizationStatus.notDetermined) {
          status = await ref
              .read(pushNotificationClientProvider)
              .requestPermission();
          ref.invalidate(pushNotificationAuthorizationProvider);
        }
        if (status != PushAuthorizationStatus.authorized &&
            status != PushAuthorizationStatus.provisional) {
          if (context.mounted) showMessage(context, l10n.notificationsDenied);
          return;
        }
      }

      await ref
          .read(notificationPreferencesRepositoryProvider)
          .setEnabled(userId, enabled);
      ref.invalidate(userNotificationsEnabledProvider(userId));
      if (enabled) {
        await ref.read(pushTokenRegistrarProvider).syncForCurrentUser();
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, l10n.notificationsPreferenceSaveFailed);
      }
    }
  }

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
    final userId = showUserPreference
        ? ref.watch(signedInUserIdProvider)
        : null;
    final preference = userId == null
        ? null
        : ref.watch(userNotificationsEnabledProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notificationPermissionTitle),
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
            if (userId != null)
              preference!.when(
                data: (enabled) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notificationsTitle),
                  subtitle: Text(
                    enabled
                        ? l10n.notificationsAccountEnabled
                        : l10n.notificationsAccountDisabled,
                  ),
                  value: enabled,
                  onChanged: (value) =>
                      _setUserPreference(context, ref, userId, value),
                ),
                error: (_, _) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notificationsPreferenceLoadFailed),
                  trailing: IconButton(
                    tooltip: l10n.retry,
                    onPressed: () => ref.invalidate(
                      userNotificationsEnabledProvider(userId),
                    ),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
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
