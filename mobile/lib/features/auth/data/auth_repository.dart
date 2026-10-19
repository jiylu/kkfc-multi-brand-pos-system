import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/auth/token_store.dart';

/// Why a sign-in attempt failed, normalized from transport/HTTP errors so
/// the UI never has to inspect [DioException] itself.
enum AuthFailure { invalidCredentials, network, unexpected }

class AuthException implements Exception {
  const AuthException(this.message, {this.kind = AuthFailure.unexpected});
  final String message;
  final AuthFailure kind;
}

class AuthRepository {
  AuthRepository(this._dio, this._store);

  final Dio _dio;
  final TokenStore _store;

  /// Signs in and persists the session token.
  ///
  /// Contract: POST /auth/login `{username, password}` ->
  /// 200 `{token, expires_at, user}` |
  /// 401 `{code: 'INVALID_CREDENTIALS', message}`.
  ///
  /// Returns the session token on success. Throws [AuthException] with the
  /// matching [AuthFailure] kind otherwise.
  Future<String> login({required String username, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      final token = res.data?['token'];
      if (token is! String || token.isEmpty) {
        throw const AuthException('Server response did not include a token.');
      }

      await _store.write(token);
      return token;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() => _store.clear();

  AuthException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      final message = e.response?.data is Map
          ? (e.response!.data['message'] as String?)?.trim()
          : null;
      return AuthException(
        (message == null || message.isEmpty)
            ? 'Invalid username or password.'
            : message,
        kind: AuthFailure.invalidCredentials,
      );
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        const AuthException('Unable to reach the server.', kind: AuthFailure.network),
      _ => const AuthException('Unexpected sign-in failure.'),
    };
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider));
});
