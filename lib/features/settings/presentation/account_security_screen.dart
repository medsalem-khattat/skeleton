import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/config/feature_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/notification_inbox_repository.dart';
import '../application/device_auth_controller.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _deviceAuthBusy = false;
  bool _accountActionBusy = false;

  Future<void> _setDeviceAuth(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _deviceAuthBusy = true);
    try {
      final authenticator = ref.read(deviceAuthenticatorProvider);
      if (!await authenticator.isDeviceSupported()) {
        if (mounted) {
          showMessage(context, l10n.deviceAuthUnavailable);
        }
        return;
      }

      final authenticated = await authenticator.authenticate(
        l10n.deviceAuthReason,
      );
      if (!mounted) return;
      if (!authenticated) {
        showMessage(context, l10n.deviceAuthFailed);
        return;
      }

      await ref.read(deviceAuthEnabledProvider.notifier).setEnabled(enabled);
    } on LocalAuthException {
      if (mounted) {
        showMessage(context, l10n.deviceAuthFailed);
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, l10n.deviceAuthSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _deviceAuthBusy = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed != true || !mounted) return;
    try {
      await ref
          .read(notificationInboxRepositoryProvider)
          .recordPasswordChanged();
      if (mounted) {
        showMessage(context, l10n.passwordChanged);
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, l10n.passwordChangedNotificationFailed);
      }
    }
  }

  Future<void> _changeEmail(String currentEmail) async {
    final l10n = AppLocalizations.of(context);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangeEmailDialog(currentEmail: currentEmail),
    );
    if (sent == true && mounted) {
      showMessage(context, l10n.emailVerificationSent);
    }
  }

  Future<void> _changePhoneNumber() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePhoneNumberDialog(
        currentPhoneNumber: ref
            .read(authRepositoryProvider)
            .currentUser
            ?.phoneNumber,
      ),
    );
    if (changed == true && mounted) {
      showMessage(context, l10n.phoneNumberChanged);
    }
  }

  Future<void> _runAccountAction({
    required String title,
    required String confirmation,
    required String failureMessage,
    required Future<void> Function(String password) action,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(title),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => _ConfirmPasswordDialog(title: title),
    );
    if (password == null || !mounted) return;

    setState(() => _accountActionBusy = true);
    try {
      await action(password);
    } catch (error) {
      if (mounted) {
        final message = switch (error) {
          FirebaseAuthException() => authErrorMessage(l10n, error),
          FirebaseFunctionsException(code: 'failed-precondition') =>
            l10n.errorRecentLogin,
          _ => failureMessage,
        };
        showMessage(context, message);
      }
    } finally {
      if (mounted) setState(() => _accountActionBusy = false);
    }
  }

  Future<void> _deleteAccount() => _runAccountAction(
    title: AppLocalizations.of(context).deleteAccount,
    confirmation: AppLocalizations.of(context).deleteAccountConfirmation,
    failureMessage: AppLocalizations.of(context).accountActionFailed,
    action: (password) => ref
        .read(accountAdminRepositoryProvider)
        .deleteAccount(currentPassword: password),
  );

  Future<void> _revokeSessions() => _runAccountAction(
    title: AppLocalizations.of(context).signOutAllSessions,
    confirmation: AppLocalizations.of(context).signOutAllSessionsConfirmation,
    failureMessage: AppLocalizations.of(context).accountActionFailed,
    action: (password) => ref
        .read(accountAdminRepositoryProvider)
        .signOutAllSessions(currentPassword: password),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = ref.watch(appFeaturesProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final deviceAuthEnabled = features.deviceAuthenticationEnabled
        ? ref.watch(deviceAuthEnabledProvider)
        : false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSecurity)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (features.deviceAuthenticationEnabled) ...[
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.phonelink_lock_outlined),
                title: Text(l10n.deviceAuthTitle),
                subtitle: Text(l10n.deviceAuthDescription),
                value: deviceAuthEnabled,
                onChanged: _deviceAuthBusy ? null : _setDeviceAuth,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text(l10n.changePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(l10n.changeEmail),
                  subtitle: Text(user?.email ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changeEmail(user?.email ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(l10n.changePhoneNumber),
                  subtitle: Text(user?.phoneNumber ?? l10n.phoneNumberNotSet),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePhoneNumber,
                ),
              ],
            ),
          ),
          if (user != null &&
              user.email != null &&
              user.providerData.any(
                (provider) => provider.providerId == 'password',
              )) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: Text(l10n.signOutAllSessions),
                    subtitle: Text(l10n.signOutAllSessionsDescription),
                    trailing: _accountActionBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _accountActionBusy ? null : _revokeSessions,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.deleteAccount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: Text(l10n.deleteAccountDescription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _accountActionBusy ? null : _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmPasswordDialog extends StatefulWidget {
  const _ConfirmPasswordDialog({required this.title});

  final String title;

  @override
  State<_ConfirmPasswordDialog> createState() => _ConfirmPasswordDialogState();
}

class _ConfirmPasswordDialogState extends State<_ConfirmPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _password,
          label: l10n.currentPassword,
          obscure: true,
          validator: Validators.password(l10n),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _password.text);
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final success = await ref
        .read(authControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    final error =
        ref.read(authControllerProvider).error ??
        StateError('Password update failed');
    setState(() {
      _loading = false;
      _errorMessage = authErrorMessage(l10n, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _currentPassword,
              label: l10n.currentPassword,
              obscure: true,
              validator: Validators.password(l10n),
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _newPassword,
              label: l10n.newPassword,
              obscure: true,
              validator: Validators.password(l10n),
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmPassword,
              label: l10n.confirmNewPassword,
              obscure: true,
              validator: (value) =>
                  value != _newPassword.text ? l10n.passwordsDoNotMatch : null,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _submit(l10n),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.changePassword),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends ConsumerStatefulWidget {
  const _ChangeEmailDialog({required this.currentEmail});

  final String currentEmail;

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newEmail = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newEmail.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyEmailChange(
          currentPassword: _currentPassword.text,
          newEmail: _newEmail.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    final error =
        ref.read(authControllerProvider).error ??
        StateError('Email update failed');
    setState(() {
      _loading = false;
      _errorMessage = authErrorMessage(l10n, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.changeEmail),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _newEmail,
              label: l10n.newEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final error = Validators.email(l10n)(value);
                if (error != null) return error;
                if (value!.trim().toLowerCase() ==
                    widget.currentEmail.toLowerCase()) {
                  return l10n.emailUnchanged;
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _currentPassword,
              label: l10n.currentPassword,
              obscure: true,
              validator: Validators.password(l10n),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _submit(l10n),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.changeEmail),
        ),
      ],
    );
  }
}

class _ChangePhoneNumberDialog extends ConsumerStatefulWidget {
  const _ChangePhoneNumberDialog({required this.currentPhoneNumber});

  final String? currentPhoneNumber;

  @override
  ConsumerState<_ChangePhoneNumberDialog> createState() =>
      _ChangePhoneNumberDialogState();
}

class _ChangePhoneNumberDialogState
    extends ConsumerState<_ChangePhoneNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumber = TextEditingController();
  final _smsCode = TextEditingController();
  final _currentPassword = TextEditingController();
  String? _verificationId;
  String? _sentPhoneNumber;
  int? _resendToken;
  PhoneAuthCredential? _autoVerifiedCredential;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneNumber.dispose();
    _smsCode.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) => value.replaceAll(RegExp(r'\s'), '');

  Future<void> _sendCode(AppLocalizations l10n, {bool resend = false}) async {
    final phoneNumber = _normalizePhone(_phoneNumber.text);
    if (phoneNumber.isEmpty) {
      setState(() => _errorMessage = l10n.phoneNumberRequired);
      return;
    }
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber)) {
      setState(() => _errorMessage = l10n.phoneNumberInvalid);
      return;
    }
    if (phoneNumber == widget.currentPhoneNumber) {
      setState(() => _errorMessage = l10n.phoneNumberUnchanged);
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
      if (resend) {
        _autoVerifiedCredential = null;
        _smsCode.clear();
      }
    });
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
    if (!mounted) return;
    if (result == null) {
      final error =
          ref.read(authControllerProvider).error ??
          StateError('Phone verification could not be started.');
      setState(() {
        _loading = false;
        _errorMessage = authErrorMessage(l10n, error);
      });
      return;
    }
    if (_normalizePhone(_phoneNumber.text) != phoneNumber) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _verificationId = result.verificationId;
      _sentPhoneNumber = phoneNumber;
      _resendToken = result.resendToken;
      _autoVerifiedCredential = result.credential ?? _autoVerifiedCredential;
      _loading = false;
    });
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final passwordError = Validators.password(l10n)(_currentPassword.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }
    if (_autoVerifiedCredential == null) {
      if (_verificationId == null ||
          _sentPhoneNumber != _normalizePhone(_phoneNumber.text) ||
          !_formKey.currentState!.validate()) {
        return;
      }
      if (!RegExp(r'^\d{6}$').hasMatch(_smsCode.text.trim())) {
        setState(() => _errorMessage = l10n.phoneVerificationCodeRequired);
        return;
      }
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final success = await ref
        .read(authControllerProvider.notifier)
        .updatePhoneNumber(
          currentPassword: _currentPassword.text,
          phoneCredential: _autoVerifiedCredential,
          verificationId: _verificationId,
          smsCode: _smsCode.text.trim().isEmpty ? null : _smsCode.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    final error =
        ref.read(authControllerProvider).error ??
        StateError('Phone number update failed.');
    setState(() {
      _loading = false;
      _errorMessage = authErrorMessage(l10n, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.changePhoneNumber),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.phoneChangeInstructions),
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneNumber,
              label: l10n.phoneNumber,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (value) {
                final phone = _normalizePhone(value ?? '');
                if (phone.isEmpty) return l10n.phoneNumberRequired;
                if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
                  return l10n.phoneNumberInvalid;
                }
                if (phone == widget.currentPhoneNumber) {
                  return l10n.phoneNumberUnchanged;
                }
                return null;
              },
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
                    _sendCode(l10n, resend: _verificationId != null),
                loading: _loading,
              )
            else
              Text(
                l10n.phoneAutomaticallyVerified,
                textAlign: TextAlign.center,
              ),
            if (_verificationId != null && _autoVerifiedCredential == null) ...[
              SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _smsCode,
                label: l10n.smsVerificationCode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
              ),
            ],
            SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _currentPassword,
              label: l10n.currentPassword,
              obscure: true,
              enabled: !_loading,
              validator: Validators.password(l10n),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed:
              _loading ||
                  (_verificationId == null && _autoVerifiedCredential == null)
              ? null
              : () => _submit(l10n),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.changePhoneNumber),
        ),
      ],
    );
  }
}
