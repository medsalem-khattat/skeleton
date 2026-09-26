import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/application/profile_providers.dart';

final appShellScaffoldKey = GlobalKey<ScaffoldState>();

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const AppNavigationDrawer(),
      body: shell,
    );
  }
}

class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key});

  void _openSettingsScreen(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push(route);
    });
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutQuestion),
        content: Text(l10n.logOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    Navigator.pop(context);
    final success = await ref.read(authControllerProvider.notifier).signOut();
    if (!success && context.mounted) {
      final error = ref.read(authControllerProvider).error;
      showMessage(
        context,
        authErrorMessage(l10n, error ?? StateError('Sign out failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final profileName = profile?.name ?? '';
    final email = currentUser?.email ?? '';
    final avatarInitial = profileName.isNotEmpty
        ? profileName.substring(0, 1)
        : email.isNotEmpty
        ? email.substring(0, 1)
        : '?';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.primary,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.profile);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 190),
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  child: Text(avatarInitial.toUpperCase()),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profileName,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  email.isNotEmpty
                                      ? email
                                      : profile?.email ?? '',
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(l10n.home),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.home);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(l10n.settings),
                    onTap: () =>
                        _openSettingsScreen(context, AppRoutes.settings),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.logOut),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('${l10n.version} ${AppConfig.appVersion}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
