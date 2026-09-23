import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
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
      if (mounted) showMessage(context, 'Profile updated');
    } catch (_) {
      if (mounted) showMessage(context, 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load your profile.')),
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
                      label: 'Full name',
                      validator: (v) => Validators.required(v, 'Name'),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                        label: 'Save changes',
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
