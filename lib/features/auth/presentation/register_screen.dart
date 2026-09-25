import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // On success the router redirects to home automatically.
    await ref
        .read(authControllerProvider.notifier)
        .register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        showMessage(context, authErrorMessage(l10n, next.error!));
      }
    });
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _name,
                      label: l10n.fullName,
                      validator: Validators.nameRequired(l10n),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _email,
                      label: l10n.email,
                      validator: Validators.email(l10n),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _password,
                      label: l10n.password,
                      validator: Validators.password(l10n),
                      obscure: true,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _confirm,
                      label: l10n.confirmPassword,
                      validator: (v) =>
                          v != _password.text ? l10n.passwordsDoNotMatch : null,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    AppButton(
                        label: l10n.createAccount,
                        onPressed: _submit,
                        loading: loading),
                    SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(l10n.haveAccount),
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
