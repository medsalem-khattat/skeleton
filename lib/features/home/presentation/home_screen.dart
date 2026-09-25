import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/application/profile_providers.dart';

/// Placeholder home screen. Replace the body with your app's real content.
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
          SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.homePlaceholder),
            ),
          ),
        ],
      ),
    );
  }
}
