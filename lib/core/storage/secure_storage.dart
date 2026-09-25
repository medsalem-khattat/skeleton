import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for any sensitive local
/// data you add later (e.g. a cached token from a future custom API,
/// a biometric-unlock flag). Not used by anything yet - Firebase Auth
/// already stores its own session securely on its own; use this only
/// for NEW sensitive values your app introduces.
///
/// Requires the `flutter_secure_storage` package:
///   flutter pub add flutter_secure_storage
class SecureStorage {
  SecureStorage._();
  static const _storage = FlutterSecureStorage();

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  /// Clears everything in secure storage. Called from
  /// AuthRepository.signOut() so nothing lingers after logout, even
  /// before this holds any real values.
  static Future<void> clearAll() => _storage.deleteAll();
}
