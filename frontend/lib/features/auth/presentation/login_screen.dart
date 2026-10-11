import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/feature_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_providers.dart';
import '../application/remembered_email_controller.dart';
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
  late bool _rememberEmail;

  @override
  void initState() {
    super.initState();
    final remembered = ref.read(appFeaturesProvider).rememberEmailEnabled
        ? ref.read(rememberedEmailProvider)
        : null;
    _email.text = remembered ?? '';
    _rememberEmail = remembered != null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text;
    final rememberEnabled = ref.read(appFeaturesProvider).rememberEmailEnabled;
    final remember = _rememberEmail;
    // Read before signing in: on success the router redirects to home
    // automatically, and this screen may be gone when signIn returns.
    final rememberedEmail = ref.read(rememberedEmailProvider.notifier);
    final signedIn = await ref
        .read(authControllerProvider.notifier)
        .signIn(email, _password.text);
    if (!signedIn || !rememberEnabled) return;
    // Not remembering the email never blocks signing in.
    if (remember) {
      await rememberedEmail.remember(email.trim());
    } else {
      await rememberedEmail.forget();
    }
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
    final rememberEnabled = ref.watch(appFeaturesProvider).rememberEmailEnabled;

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
                    if (rememberEnabled)
                      CheckboxListTile(
                        value: _rememberEmail,
                        onChanged: (value) =>
                            setState(() => _rememberEmail = value ?? false),
                        title: Text(l10n.rememberEmail),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.signIn,
                      onPressed: _submit,
                      loading: loading,
                    ),
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
