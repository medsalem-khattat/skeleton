import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // On success the router redirects to home automatically.
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
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
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(l10n.signInToContinue, textAlign: TextAlign.center),
                    SizedBox(height: AppSpacing.xl),
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
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    AppButton(
                        label: l10n.signIn,
                        onPressed: _submit,
                        loading: loading),
                    SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(l10n.forgotPassword),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: Text(l10n.createAnAccount),
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
