import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../application/profile_providers.dart';
import '../../home/presentation/home_shell.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateName(user, _name.text.trim());
      if (mounted) {
        showMessage(context, AppLocalizations.of(context).profileUpdated);
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, AppLocalizations.of(context).saveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );

    if (changed == true && mounted) {
      showMessage(context, l10n.passwordChanged);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(
          tooltip: l10n.openMenu,
          icon: const Icon(Icons.menu),
          onPressed: () => appShellScaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.profileLoadFailed),
                SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          if (!_initialized) {
            _name.text = p.name;
            _initialized = true;
          }
          final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Center(child: Text(p.email)),
              SizedBox(height: AppSpacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _name,
                      label: l10n.fullName,
                      validator: Validators.nameRequired(l10n),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.saveChanges,
                      onPressed: _save,
                      loading: _saving,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                l10n.accountSecurity,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: AppSpacing.sm),
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _changeEmail(p.email),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
