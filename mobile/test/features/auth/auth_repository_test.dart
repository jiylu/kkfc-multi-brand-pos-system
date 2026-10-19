import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';

class _FakeTokenStore extends TokenStore {
  String? written;
  bool cleared = false;

  @override
  Future<void> write(String token) async {
    written = token;
  }

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

/// Captures the outgoing request and hands the encoded body to [respond].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(String? body) respond;
  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? body;
    if (requestStream != null) {
      final buffer = <int>[];
      await for (final chunk in requestStream) {
        buffer.addAll(chunk);
      }
      body = utf8.decode(buffer);
    }

    lastRequest = options;
    lastBody = body;
    return respond(body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

AuthRepository _repo(_FakeAdapter adapter, TokenStore store) => AuthRepository(
  Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))..httpClientAdapter = adapter,
  store,
);

void main() {
  test(
    'posts credentials to /api/auth/login and stores the session token',
    () async {
      final store = _FakeTokenStore();
      final adapter = _FakeAdapter(
        (_) async => _json({
          'token': 'tok-123',
          'expires_at': '2026-10-21T12:00:00.000Z',
          'user': {'user_id': 'u1', 'username': 'test_owner', 'role': 'OWNER'},
        }),
      );
      final repo = _repo(adapter, store);

      final token = await repo.login(
        username: 'test_owner',
        password: 'Password123!',
      );

      expect(token, 'tok-123');
      expect(store.written, 'tok-123');

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'http://localhost:3000/api/auth/login');
      expect(jsonDecode(adapter.lastBody!), {
        'username': 'test_owner',
        'password': 'Password123!',
      });
    },
  );

  test(
    'a 401 becomes an invalidCredentials failure with the server message',
    () async {
      final store = _FakeTokenStore();
      final adapter = _FakeAdapter(
        (_) async => _json({
          'code': 'INVALID_CREDENTIALS',
          'message': 'Invalid username or password.',
        }, status: 401),
      );
      final repo = _repo(adapter, store);

      try {
        await repo.login(username: 'test_owner', password: 'wrong');
        fail('Expected an AuthException.');
      } on AuthException catch (e) {
        expect(e.kind, AuthFailure.invalidCredentials);
        expect(e.message, 'Invalid username or password.');
      }
      expect(store.written, isNull);
    },
  );

  test('a connection failure becomes a network failure', () async {
    final store = _FakeTokenStore();
    final adapter = _FakeAdapter((_) async {
      throw DioException.connectionError(
        requestOptions: RequestOptions(
          baseUrl: AppConfig.apiBaseUrl,
          path: '/auth/login',
        ),
        reason: 'Connection refused',
      );
    });
    final repo = _repo(adapter, store);

    try {
      await repo.login(username: 'test_owner', password: 'Password123!');
      fail('Expected an AuthException.');
    } on AuthException catch (e) {
      expect(e.kind, AuthFailure.network);
    }
    expect(store.written, isNull);
  });

  test(
    'a success payload without a token becomes an unexpected failure',
    () async {
      final store = _FakeTokenStore();
      final adapter = _FakeAdapter(
        (_) async => _json({'expires_at': '2026-10-21T12:00:00.000Z'}),
      );
      final repo = _repo(adapter, store);

      try {
        await repo.login(username: 'test_owner', password: 'Password123!');
        fail('Expected an AuthException.');
      } on AuthException catch (e) {
        expect(e.kind, AuthFailure.unexpected);
        expect(e.message, 'Server response did not include a token.');
      }
      expect(store.written, isNull);
    },
  );

  test(
    'logout ends the server session with the token and clears the store',
    () async {
      final store = _FakeTokenStore();
      final adapter = _FakeAdapter(
        (_) async => ResponseBody.fromString('', 204),
      );
      final repo = _repo(adapter, store);

      await repo.logout('tok-123');

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'http://localhost:3000/api/auth/logout');
      expect(request.headers['Authorization'], 'Bearer tok-123');
      expect(store.cleared, isTrue);
    },
  );

  test(
    'logout still clears the store when the server is unreachable',
    () async {
      final store = _FakeTokenStore();
      final adapter = _FakeAdapter((_) async {
        throw DioException.connectionError(
          requestOptions: RequestOptions(
            baseUrl: AppConfig.apiBaseUrl,
            path: '/auth/logout',
          ),
          reason: 'Connection refused',
        );
      });
      final repo = _repo(adapter, store);

      await repo.logout('tok-123');

      expect(store.cleared, isTrue);
    },
  );
}
