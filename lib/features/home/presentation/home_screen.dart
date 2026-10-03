import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/feature_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/data/notification_inbox_repository.dart';
import '../../profile/application/profile_providers.dart';
import 'home_shell.dart';

/// Dashboard for the profile and settings features currently in the skeleton.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(appFeaturesProvider);
    final l10n = AppLocalizations.of(context);
    final name = features.profileEnabled
        ? ref.watch(profileProvider).value?.name ?? ''
        : '';
    final notifications = features.notificationInboxEnabled
        ? ref.watch(notificationInboxProvider)
        : null;
    final unreadCount =
        notifications?.asData?.value
            .where((notification) => !notification.isRead)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        leading: IconButton(
          tooltip: l10n.openMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (features.notificationInboxEnabled)
            IconButton(
              tooltip: unreadCount == 0
                  ? l10n.notificationsTitle
                  : l10n.notificationUnreadCount(unreadCount),
              onPressed: () => context.push(AppRoutes.notifications),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            name.isEmpty ? l10n.welcome : l10n.welcomeName(name),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (features.profileEnabled) ...[
            SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.dashboardProfileTitle),
                subtitle: Text(l10n.dashboardProfileDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.profile),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
