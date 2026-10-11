import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/theme_controller.dart';

/// The email address the user chose to remember on this device, or null.
/// Only the email is stored, never the password.
class RememberedEmailController extends Notifier<String?> {
  static const _key = 'remembered_email';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  /// Saves [email]; returns false if the device could not store it.
  Future<bool> remember(String email) async {
    final saved = await ref
        .read(sharedPreferencesProvider)
        .setString(_key, email);
    if (saved) state = email;
    return saved;
  }

  /// Removes the remembered email; returns false if the device could not.
  Future<bool> forget() async {
    final removed = await ref.read(sharedPreferencesProvider).remove(_key);
    if (removed) state = null;
    return removed;
  }
}

final rememberedEmailProvider =
    NotifierProvider<RememberedEmailController, String?>(
      RememberedEmailController.new,
    );
