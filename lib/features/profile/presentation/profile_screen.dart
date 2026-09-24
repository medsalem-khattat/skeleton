import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.profileLoadFailed)),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          if (!_initialized) {
            _name.text = p.name;
            _initialized = true;
          }
          final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Text(initial,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(p.email)),
              const SizedBox(height: 32),
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
                    const SizedBox(height: 24),
                    AppButton(
                        label: l10n.saveChanges,
                        onPressed: _save,
                        loading: _saving),
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
