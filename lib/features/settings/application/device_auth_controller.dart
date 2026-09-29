import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'theme_controller.dart';

abstract interface class DeviceAuthenticator {
  Future<bool> isDeviceSupported();
  Future<bool> authenticate(String localizedReason);
}

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate(String localizedReason) => _auth.authenticate(
    localizedReason: localizedReason,
    persistAcrossBackgrounding: true,
  );
}

final deviceAuthenticatorProvider = Provider<DeviceAuthenticator>(
  (ref) => LocalDeviceAuthenticator(LocalAuthentication()),
);

class DeviceAuthController extends Notifier<bool> {
  static const _key = 'device_auth_enabled';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
  }
}

final deviceAuthEnabledProvider = NotifierProvider<DeviceAuthController, bool>(
  DeviceAuthController.new,
);
