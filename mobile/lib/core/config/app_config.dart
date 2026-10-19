abstract final class AppConfig {
  static const rawApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static String get apiBaseUrl => normalizeApiBaseUrl(rawApiUrl, env: env);
}

/// Checks a configured API URL and returns it without a trailing slash.
String normalizeApiBaseUrl(String raw, {required String env}) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);

  if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
    throw ArgumentError.value(
      raw,
      'API_URL',
      'must be an absolute URL such as http://localhost:3001',
    );
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw ArgumentError.value(raw, 'API_URL', 'must use http or https');
  }
  if (env == 'prod' && uri.scheme != 'https') {
    throw ArgumentError.value(
      raw,
      'API_URL',
      'must use https when ENV is prod',
    );
  }

  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
