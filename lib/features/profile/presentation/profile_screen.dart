import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';
import '../data/profile_repository.dart';
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
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
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
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showMessage(
          context,
          error is ProfileNameSyncException
              ? l10n.profileSyncFailed
              : l10n.saveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto(String? previousStoragePath) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      await ref
          .read(profileRepositoryProvider)
          .uploadProfilePhoto(
            user,
            await image.readAsBytes(),
            previousStoragePath: previousStoragePath,
          );
      ref.invalidate(profileProvider);
      if (mounted) showMessage(context, l10n.profilePhotoUpdated);
    } on ProfilePhotoCleanupException {
      if (mounted) showMessage(context, l10n.profilePhotoCleanupFailed);
    } on ArgumentError {
      if (mounted) showMessage(context, l10n.profilePhotoTooLarge);
    } catch (_) {
      if (mounted) showMessage(context, l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removePhoto(String? storagePath) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .removeProfilePhoto(user, storagePath: storagePath);
      ref.invalidate(profileProvider);
      if (mounted) showMessage(context, l10n.profilePhotoRemoved);
    } on ProfilePhotoRemovalCleanupException {
      if (mounted) showMessage(context, l10n.profilePhotoRemovalCleanupFailed);
    } catch (_) {
      if (mounted) showMessage(context, l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
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
          final photo = p.photoStoragePath == null
              ? null
              : ref.watch(profilePhotoBytesProvider(p.photoStoragePath!));
          final photoBytes = photo?.when(
            data: (bytes) => bytes,
            error: (_, _) => null,
            loading: () => null,
          );
          final ImageProvider<Object>? profileImage = photoBytes != null
              ? MemoryImage(photoBytes)
              : p.photoStoragePath == null && p.photoUrl != null
              ? NetworkImage(p.photoUrl!)
              : null;
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? Text(
                              initial,
                              style: Theme.of(context).textTheme.headlineMedium,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _changePhoto(p.photoStoragePath),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.changeProfilePhoto),
                        ),
                        if (p.photoStoragePath != null)
                          TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _removePhoto(p.photoStoragePath),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.removeProfilePhoto),
                          ),
                      ],
                    ),
                    if (_saving) const LinearProgressIndicator(),
                  ],
                ),
              ),
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
            ],
          );
        },
      ),
    );
  }
}
