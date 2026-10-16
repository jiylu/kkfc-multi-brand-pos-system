abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );
  static const env = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
}