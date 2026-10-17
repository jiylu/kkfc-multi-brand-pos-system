import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readToken, this.onUnauthorized});

  /// Returns the current access token, or null when signed out.
  final String? Function() readToken;

  /// Called with the token the server rejected.
  final void Function(String rejectedToken)? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isLogin = err.requestOptions.path.endsWith('/auth/login');
    final sent = _sentToken(err.requestOptions);

    if (err.response?.statusCode == 401 && !isLogin && sent != null) {
      onUnauthorized?.call(sent);
    }
    handler.next(err);
  }

  String? _sentToken(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring(7);
    }
    return null;
  }
}