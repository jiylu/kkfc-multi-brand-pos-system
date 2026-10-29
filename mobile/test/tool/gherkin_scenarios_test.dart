import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gherkin_scenarios.dart';
import '../../tool/integration_report.dart';

void main() {
  late List<Map<String, String>> scenarios;
  setUp(() {
    scenarios = readAuthScenarios(
      File('../features/mobile/auth-api.integration.feature')
          .readAsStringSync(),
    );
  });

  test(
    'real feature maps test IDs to scenarios and preserves Gherkin steps',
    () {
      final results = scenarioResults(scenarios, [
        {
          'name': 'IT-MOB-AUTH-001 valid credentials create a real API session',
          'status': 'Passed',
        },
        {
          'name': 'IT-MOB-AUTH-002 wrong password shows invalid credentials',
          'status': 'Failed',
        },
      ]);
      expect(results.map((s) => s['status']), ['Passed', 'Failed']);
      expect(results.first['name'], 'Successful staff login');
      expect(
        results.first['gherkin'],
        contains('Then the app opens the menu screen'),
      );
    },
  );

  test('missing tests are not run and similar ID prefixes do not match', () {
    final results = scenarioResults(scenarios, [
      {'name': 'IT-MOB-AUTH-0010 another test', 'status': 'Passed'},
    ]);
    expect(results.map((s) => s['status']), everyElement('Not run'));
  });

  test('one failed variant makes the mapped scenario fail', () {
    final results = scenarioResults(scenarios, [
      {'name': 'IT-MOB-AUTH-001 variant A', 'status': 'Passed'},
      {'name': 'IT-MOB-AUTH-001 variant B', 'status': 'Failed'},
    ]);
    expect(results.first['status'], 'Failed');
  });

  test(
    'exports valid result comments and renders descriptive steps in HTML',
    () {
      final report = IntegrationReport().summarize(
        exitCode: 1,
        started: DateTime.utc(2026),
        finished: DateTime.utc(2026),
        arguments: [],
        scenarios: scenarios,
      );
      final gherkin = gherkinWithResults(report);
      expect(gherkin, contains('# Result: Not run'));
      expect(gherkin, contains('@IT-MOB-AUTH-001'));
      expect(readAuthScenarios(gherkin), scenarios);
      final html = reportHtml(report);
      expect(html, contains('Gherkin scenarios'));
      expect(html, contains('IT-MOB-AUTH-002 — Not run'));
      expect(html, contains('Scenario: Reject an incorrect password'));
    },
  );

  test('missing and duplicate ID tags cannot silently mislabel results', () {
    expect(
      () => readAuthScenarios('Feature: Login\nScenario: Login\nGiven a user'),
      throwsFormatException,
    );
    final source = File('../features/mobile/auth-api.integration.feature')
        .readAsStringSync()
        .replaceAll('IT-MOB-AUTH-002', 'IT-MOB-AUTH-001');
    expect(() => readAuthScenarios(source), throwsFormatException);
  });

  test('POS scenarios map only to their separate integration test IDs', () {
    final pos = readAuthScenarios(
      File('../features/mobile/pos-core.integration.feature')
          .readAsStringSync(),
    );
    expect(pos.map((s) => s['id']), [
      'IT-MOB-POS-001',
      'IT-MOB-POS-002',
      'IT-MOB-POS-003',
    ]);
    final results = scenarioResults(pos, [
      {'name': 'IT-MOB-POS-001 core flow', 'status': 'Passed'},
      {'name': 'IT-MOB-AUTH-001 login', 'status': 'Passed'},
    ]);
    expect(results.map((s) => s['status']), ['Passed', 'Not run', 'Not run']);
  });
}
