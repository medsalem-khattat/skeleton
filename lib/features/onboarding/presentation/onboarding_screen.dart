import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).complete();
      if (!mounted) return;
      final features = ref.read(appFeaturesProvider);
      context.go(
        features.authentication ? AppRoutes.login : features.initialLocation,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, AppLocalizations.of(context).onboardingSaveFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      _OnboardingPage(
        icon: Icons.dashboard_outlined,
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      _OnboardingPage(
        icon: Icons.security_outlined,
        title: l10n.onboardingSecurityTitle,
        body: l10n.onboardingSecurityBody,
      ),
      _OnboardingPage(
        icon: Icons.tune_outlined,
        title: l10n.onboardingControlTitle,
        body: l10n.onboardingControlBody,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _saving ? null : _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Semantics(
                    label: l10n.onboardingPageSemantics(
                      index + 1,
                      pages.length,
                    ),
                    selected: _page == index,
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _page == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _page == pages.length - 1
                    ? l10n.onboardingGetStarted
                    : l10n.onboardingNext,
                onPressed: _saving
                    ? null
                    : () {
                        if (_page == pages.length - 1) {
                          _finish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary,
              semanticLabel: title,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
