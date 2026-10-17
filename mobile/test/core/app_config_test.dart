import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/config/app_config.dart';

void main() {
  test('removes a trailing slash', () {
    expect(
      normalizeApiBaseUrl('http://localhost:3001/', env: 'dev'),
      'http://localhost:3001',
    );
  });

  test('rejects relative and non-http URLs', () {
    expect(() => normalizeApiBaseUrl('localhost:3001', env: 'dev'), throwsArgumentError);
    expect(() => normalizeApiBaseUrl('ftp://example.com', env: 'dev'), throwsArgumentError);
    expect(() => normalizeApiBaseUrl('', env: 'dev'), throwsArgumentError);
  });

  test('prod requires https', () {
    expect(() => normalizeApiBaseUrl('http://api.example.com', env: 'prod'), throwsArgumentError);
    expect(
      normalizeApiBaseUrl('https://api.example.com/', env: 'prod'),
      'https://api.example.com',
    );
  });
}