import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class EmailActionScreen extends ConsumerStatefulWidget {
  const EmailActionScreen({
    required this.mode,
    required this.actionCode,
    super.key,
  });

  final String? mode;
  final String? actionCode;

  @override
  ConsumerState<EmailActionScreen> createState() => _EmailActionScreenState();
}

class _EmailActionScreenState extends ConsumerState<EmailActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = true;
  bool _resetPassword = false;
  bool _error = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processAction());
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _processAction() async {
    final code = widget.actionCode;
    final mode = widget.mode;
    final l10n = AppLocalizations.of(context);
    if (code == null || code.isEmpty || mode == null) {
      _setMessage(l10n.authActionInvalidLink, error: true);
      return;
    }
    try {
      final repository = ref.read(authRepositoryProvider);
      switch (mode) {
        case 'verifyEmail':
          await repository.applyEmailActionCode(code);
          await repository.currentUser?.reload();
          _setMessage(l10n.authActionVerified);
          break;
        case 'verifyAndChangeEmail':
          await repository.applyEmailActionCode(code);
          await repository.currentUser?.reload();
          _setMessage(l10n.authActionVerified);
          break;
        case 'recoverEmail':
          await repository.applyEmailActionCode(code);
          await repository.currentUser?.reload();
          _setMessage(l10n.authActionEmailRecovered);
          break;
        case 'resetPassword':
          await repository.verifyPasswordResetCode(code);
          if (!mounted) return;
          setState(() {
            _loading = false;
            _resetPassword = true;
          });
          break;
        default:
          _setMessage(l10n.authActionInvalidLink, error: true);
      }
    } on FirebaseAuthException catch (error) {
      _setMessage(authErrorMessage(l10n, error), error: true);
    } catch (error) {
      _setMessage(authErrorMessage(l10n, error), error: true);
    }
  }

  void _setMessage(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = message;
      _error = error;
    });
  }

  Future<void> _submitPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPasswordReset(
            code: widget.actionCode!,
            newPassword: _password.text,
          );
      _setMessage(l10n.authActionPasswordChanged);
      setState(() => _resetPassword = false);
    } catch (error) {
      _setMessage(authErrorMessage(l10n, error), error: true);
    }
  }

  void _continue() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authActionTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_resetPassword)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.resetInstructions),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _password,
                            label: l10n.newPassword,
                            obscure: true,
                            validator: Validators.password(l10n),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _confirmPassword,
                            label: l10n.confirmNewPassword,
                            obscure: true,
                            validator: (value) => value != _password.text
                                ? l10n.passwordsDoNotMatch
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: l10n.authActionSubmit,
                            loading: _loading,
                            onPressed: _submitPasswordReset,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Icon(
                      _error
                          ? Icons.error_outline
                          : Icons.mark_email_read_outlined,
                      size: 64,
                      color: _error
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _message ?? l10n.authActionInstructions,
                      textAlign: TextAlign.center,
                    ),
                    if (!_error) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: l10n.authActionContinue,
                        onPressed: _continue,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
