import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access token and user role in the platform's secure storage.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  static const _roleKey = 'user_role';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<String?> readRole() async {
    try {
      return await _storage.read(key: _roleKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeRole(String role) async {
    try {
      await _storage.write(key: _roleKey, value: role);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
    try {
      await _storage.delete(key: _roleKey);
    } catch (_) {}
  }
}

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());
