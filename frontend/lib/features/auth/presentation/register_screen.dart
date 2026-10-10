import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_providers.dart';
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
  final _phoneNumber = TextEditingController();
  final _smsCode = TextEditingController();
  String? _verificationId;
  String? _sentPhoneNumber;
  int? _resendToken;
  PhoneAuthCredential? _autoVerifiedCredential;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phoneNumber.dispose();
    _smsCode.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) => value.replaceAll(RegExp(r'\s'), '');

  String? _phoneNumberError(String? value, AppLocalizations l10n) {
    final phone = _normalizePhone(value ?? '');
    if (phone.isEmpty) return l10n.phoneNumberRequired;
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)
        ? null
        : l10n.phoneNumberInvalid;
  }

  Future<void> _sendPhoneCode({bool resend = false}) async {
    final l10n = AppLocalizations.of(context);
    final phoneNumber = _normalizePhone(_phoneNumber.text);
    final phoneError = _phoneNumberError(phoneNumber, l10n);
    if (phoneError != null) {
      showMessage(context, phoneError);
      return;
    }
    if (resend) {
      setState(() {
        _autoVerifiedCredential = null;
        _smsCode.clear();
      });
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPhoneVerificationCode(
          phoneNumber: phoneNumber,
          forceResendingToken: resend ? _resendToken : null,
          onVerificationCompleted: (credential) {
            if (!mounted || _normalizePhone(_phoneNumber.text) != phoneNumber) {
              return;
            }
            setState(() => _autoVerifiedCredential = credential);
          },
        );
    if (!mounted ||
        result == null ||
        _normalizePhone(_phoneNumber.text) != phoneNumber) {
      return;
    }
    setState(() {
      _verificationId = result.verificationId;
      _sentPhoneNumber = phoneNumber;
      _resendToken = result.resendToken;
      _autoVerifiedCredential = result.credential ?? _autoVerifiedCredential;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final phoneRequired = ref
        .read(appFeaturesProvider)
        .phoneVerificationEnabled;
    if (phoneRequired &&
        _autoVerifiedCredential == null &&
        (_verificationId == null || _sentPhoneNumber == null)) {
      showMessage(context, l10n.phoneRegistrationRequired);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phoneCredential: phoneRequired ? _autoVerifiedCredential : null,
          verificationId: phoneRequired ? _verificationId : null,
          smsCode: !phoneRequired || _smsCode.text.trim().isEmpty
              ? null
              : _smsCode.text.trim(),
        );
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
    final phoneRequired = ref
        .watch(appFeaturesProvider)
        .phoneVerificationEnabled;

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
                    if (phoneRequired) ...[
                      Text(
                        l10n.phoneRegistrationInstructions,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.md),
                    ],
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
                      validator: (value) => value != _password.text
                          ? l10n.passwordsDoNotMatch
                          : null,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                    ),
                    if (phoneRequired) ...[
                      SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _phoneNumber,
                        label: l10n.phoneNumber,
                        enabled: !loading,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (value) => _phoneNumberError(value, l10n),
                        onChanged: (value) {
                          if (_sentPhoneNumber != null &&
                              _normalizePhone(value) != _sentPhoneNumber) {
                            setState(() {
                              _verificationId = null;
                              _sentPhoneNumber = null;
                              _resendToken = null;
                              _autoVerifiedCredential = null;
                              _smsCode.clear();
                            });
                          }
                        },
                      ),
                      SizedBox(height: AppSpacing.sm),
                      if (_autoVerifiedCredential == null)
                        AppButton(
                          label: _verificationId == null
                              ? l10n.sendVerificationCode
                              : l10n.resendVerificationCode,
                          onPressed: () =>
                              _sendPhoneCode(resend: _verificationId != null),
                          loading: loading,
                        )
                      else
                        Text(
                          l10n.phoneAutomaticallyVerified,
                          textAlign: TextAlign.center,
                        ),
                      if (_verificationId != null &&
                          _autoVerifiedCredential == null) ...[
                        SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          controller: _smsCode,
                          label: l10n.smsVerificationCode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          validator: (value) {
                            if (value?.trim().isNotEmpty == true &&
                                RegExp(r'^\d{6}$').hasMatch(value!.trim())) {
                              return null;
                            }
                            return l10n.phoneVerificationCodeRequired;
                          },
                        ),
                      ],
                    ],
                    SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.createAccount,
                      onPressed: _submit,
                      loading: loading,
                    ),
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
