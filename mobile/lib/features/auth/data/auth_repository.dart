import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/auth/token_store.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class AuthRepository {
  AuthRepository(this._dio, this._store);

  final Dio _dio;
  final TokenStore _store;

  /// Assumed contract: POST /auth/login {username, password} -> {accessToken}.
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final token = res.data?['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const AuthException('Server response did not include a token.');
    }

    await _store.write(token);
    return token;
  }

  Future<void> logout() => _store.clear();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));
});
