import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_update_policy.dart';

class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appUpdateRequirementProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          debugPrint('Could not evaluate the minimum app version: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );
    });

    final requirement = ref.watch(appUpdateRequirementProvider);
    return requirement.when(
      loading: () => const _UpdateCheckLoadingScreen(),
      error: (error, stackTrace) => _UpdateCheckErrorScreen(
        onRetry: () => ref.invalidate(appUpdateRequirementProvider),
      ),
      data: (value) =>
          value == null ? child : _ForceUpdateScreen(requirement: value),
    );
  }
}

class _UpdateCheckLoadingScreen extends StatelessWidget {
  const _UpdateCheckLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.forceUpdateChecking),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({required this.requirement});

  final AppUpdateRequirement requirement;

  Future<void> _openStore(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final opened = await launchUrl(
        requirement.storeUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showLaunchError(context, l10n.forceUpdateStoreUnavailable);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not open the app store: $error\n$stackTrace');
      if (context.mounted) {
        _showLaunchError(context, l10n.forceUpdateStoreUnavailable);
      }
    }
  }

  void _showLaunchError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update_alt,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.forceUpdateTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.forceUpdateMessage(requirement.minimumVersion),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.forceUpdateAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateCheckErrorScreen extends StatelessWidget {
  const _UpdateCheckErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.forceUpdateCheckFailedTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.forceUpdateCheckFailedMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.forceUpdateRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
