import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  static const _verificationCheckInterval = Duration(seconds: 5);

  Timer? _verificationTimer;
  bool _busy = false;
  bool _checkingVerification = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVerification();
    });
    _verificationTimer = Timer.periodic(
      _verificationCheckInterval,
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification();
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    final sent = await ref
        .read(authControllerProvider.notifier)
        .resendEmailVerification();
    if (!mounted) return;

    setState(() {
      _busy = false;
      _messageIsError = !sent;
      _message = sent
          ? AppLocalizations.of(context).verificationEmailSent
          : authErrorMessage(
              AppLocalizations.of(context),
              ref.read(authControllerProvider).error ??
                  StateError('Verification email could not be sent'),
            );
    });
  }

  Future<void> _checkVerification() async {
    if (_checkingVerification || _busy) return;
    _checkingVerification = true;

    try {
      final isVerified = await ref
          .read(authControllerProvider.notifier)
          .reloadEmailVerification();
      if (!mounted) return;

      if (isVerified == true) {
        _verificationTimer?.cancel();
        context.go(AppRoutes.home);
        return;
      }

      if (isVerified == null && _message == null) {
        setState(() {
          _messageIsError = true;
          _message = authErrorMessage(
            AppLocalizations.of(context),
            ref.read(authControllerProvider).error ??
                StateError('Verification status could not be checked'),
          );
        });
      } else if (isVerified == false && _messageIsError && mounted) {
        setState(() {
          _message = null;
          _messageIsError = false;
        });
      }
    } finally {
      _checkingVerification = false;
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final success = await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.login);
      return;
    }
    setState(() {
      _busy = false;
      _messageIsError = true;
      _message = authErrorMessage(
        AppLocalizations.of(context),
        ref.read(authControllerProvider).error ?? StateError('Sign out failed'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(authRepositoryProvider).currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.verifyEmailInstructions,
                    textAlign: TextAlign.center,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _messageIsError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.resendVerificationEmail,
                    onPressed: _resendEmail,
                    loading: _busy,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _busy ? null : _signOut,
                    child: Text(l10n.logOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
