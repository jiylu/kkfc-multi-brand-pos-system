import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readToken, this.onUnauthorized});

  /// Returns the current access token, or null when signed out.
  final String? Function() readToken;

  /// Called when a protected request returns 401.
  final void Function()? onUnauthorized;

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
    if (err.response?.statusCode == 401 && !isLogin) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}