import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/application/profile_providers.dart';

/// Dashboard for the profile and settings features currently in the skeleton.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(profileProvider).value?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            name.isEmpty ? l10n.welcome : l10n.welcomeName(name),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(l10n.dashboardProfileTitle),
              subtitle: Text(l10n.dashboardProfileDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.profile),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.tune)),
              title: Text(l10n.dashboardSettingsTitle),
              subtitle: Text(l10n.dashboardSettingsDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.settings),
            ),
          ),
        ],
      ),
    );
  }
}
