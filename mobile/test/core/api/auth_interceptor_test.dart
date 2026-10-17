import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/api/auth_interceptor.dart';

class _CaptureAdapter implements HttpClientAdapter {
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
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(String? Function() readToken) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = _CaptureAdapter();
  dio.interceptors.add(AuthInterceptor(readToken: readToken));
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
}