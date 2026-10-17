import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/api/auth_interceptor.dart';

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.status = 200});

  final int status;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(
  String? Function() readToken, {
  int status = 200,
  void Function(String)? onUnauthorized,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = _CaptureAdapter(status: status);
  dio.interceptors.add(
    AuthInterceptor(readToken: readToken, onUnauthorized: onUnauthorized),
  );
  return dio;
}

void main() {
  test('sends the Bearer token when signed in', () async {
    final dio = _dioWith(() => 'abc123');
    await dio.get<dynamic>('/orders');

    final adapter = dio.httpClientAdapter as _CaptureAdapter;
    expect(adapter.last!.headers['Authorization'], 'Bearer abc123');
  });

  test('sends no Authorization header when signed out', () async {
    final dio = _dioWith(() => null);
    await dio.get<dynamic>('/orders');

    final adapter = dio.httpClientAdapter as _CaptureAdapter;
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
  });

    test('401 on a protected request reports the rejected token', () async {
    String? rejected;
    final dio = _dioWith(
      () => 'abc123',
      status: 401,
      onUnauthorized: (t) => rejected = t,
    );

    await expectLater(dio.get<dynamic>('/orders'), throwsA(isA<DioException>()));
    expect(rejected, 'abc123');
  });

  test('401 from the login endpoint does not sign out', () async {
    var called = false;
    final dio = _dioWith(
      () => 'abc123',
      status: 401,
      onUnauthorized: (_) => called = true,
    );

    await expectLater(dio.post<dynamic>('/auth/login'), throwsA(isA<DioException>()));
    expect(called, isFalse);
  });

  test('401 on a request that sent no token does not sign out', () async {
    var called = false;
    final dio = _dioWith(
      () => null,
      status: 401,
      onUnauthorized: (_) => called = true,
    );

    await expectLater(dio.get<dynamic>('/orders'), throwsA(isA<DioException>()));
    expect(called, isFalse);
  });
}