import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/auth_interceptor.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      readToken: () => ref.read(sessionTokenProvider),
      onUnauthorized: (rejectedToken) =>
          ref.read(sessionTokenProvider.notifier).expire(rejectedToken),
    ),
  );

  return dio;
});