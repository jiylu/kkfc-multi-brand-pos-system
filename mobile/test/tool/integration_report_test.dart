import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/integration_report.dart';

void main() {
  test('HTML retains framework diagnostics emitted as print events', () {
    final parser = IntegrationReport();
    for (final event in [
      {
        'type': 'testStart',
        'test': {'id': 1, 'name': 'cart review'},
        'time': 0,
      },
      {
        'type': 'print',
        'testID': 1,
        'messageType': 'print',
        'message': 'A RenderFlex overflowed by 62 pixels.',
      },
      {
        'type': 'error',
        'testID': 1,
        'error': 'Test failed. See exception logs above.',
        'stackTrace': '',
      },
      {
        'type': 'testDone',
        'testID': 1,
        'result': 'error',
        'hidden': false,
        'time': 10,
      },
      {'type': 'done', 'success': false},
    ]) {
      parser.addLine(jsonEncode(event));
    }
    final summary = parser.summarize(
      exitCode: 1,
      started: DateTime.utc(2026),
      finished: DateTime.utc(2026),
      arguments: [],
    );
    expect(
      reportHtml(summary),
      contains('A RenderFlex overflowed by 62 pixels.'),
    );
  });
  late IntegrationReport report;
  setUp(() => report = IntegrationReport());

  void event(Map<String, dynamic> value) => report.addLine(jsonEncode(value));
  void start(int id, String name) => event({
    'type': 'testStart',
    'time': 10,
    'test': {'id': id, 'name': name},
  });
  void done(int id, {bool hidden = false, bool skipped = false}) => event({
    'type': 'testDone',
    'testID': id,
    'result': 'success',
    'hidden': hidden,
    'skipped': skipped,
    'time': 60,
  });
  Map<String, dynamic> summary({int exitCode = 0}) => report.summarize(
    exitCode: exitCode,
    started: DateTime.utc(2026),
    finished: DateTime.utc(2026).add(const Duration(seconds: 1)),
    arguments: ['test', '--machine'],
  );

  test(
    'counts cases, ignores successful lifecycle events and build output',
    () {
      report.addLine('Building APK...');
      start(0, 'loading integration_test/auth_api_test.dart');
      done(0, hidden: true);
      start(1, 'login');
      done(1);
      start(2, 'optional case');
      done(2, skipped: true);
      event({'type': 'done', 'success': true});

      final result = summary();
      expect(result['status'], 'Passed');
      expect(result['counts'], {
        'Passed': 1,
        'Failed': 0,
        'Skipped': 1,
        'Not completed': 0,
      });
      expect((result['tests'] as List).first['durationMs'], 50);
    },
  );

  test('late errors override earlier success and preserve diagnostics', () {
    start(1, 'login');
    done(1);
    event({
      'type': 'error',
      'testID': 1,
      'error': 'Expected a valid session',
      'stackTrace': 'auth_api_test.dart:50',
      'isFailure': true,
    });
    event({'type': 'done', 'success': false});
    final result = summary(exitCode: 1);
    expect(result['status'], 'Failed');
    expect(result['counts']['Passed'], 0);
    expect(result['counts']['Failed'], 1);
    expect(reportHtml(result), contains('Expected a valid session'));
    expect(reportHtml(result), contains('auth_api_test.dart:50'));
  });

  test('setup failure is a blocker, not a product test failure', () {
    start(1, '(setUpAll)');
    event({
      'type': 'error',
      'testID': 1,
      'error': 'Missing API_URL',
      'stackTrace': '',
    });
    event({'type': 'done', 'success': false});
    final result = summary(exitCode: 1);
    expect(result['status'], 'Blocked');
    expect(result['tests'], isEmpty);
    expect(result['blockers'].join(), contains('Missing API_URL'));
  });

  test('missing or incomplete protocol never produces a passing report', () {
    expect(summary()['status'], 'Blocked');
    start(1, 'login');
    expect(summary()['status'], 'Blocked');
    expect(summary()['counts']['Not completed'], 1);
    done(1);
    expect(summary()['status'], 'Blocked');
  });

  test('all skipped is reported separately from passed', () {
    start(1, 'login');
    done(1, skipped: true);
    event({'type': 'done', 'success': true});
    expect(summary()['status'], 'Skipped');
  });

  test('HTML escapes test diagnostics and names', () {
    start(1, '<script>alert(1)</script>');
    event({
      'type': 'error',
      'testID': 1,
      'error': '<img src=x onerror=alert(1)>',
      'stackTrace': 'a & b',
    });
    event({'type': 'done', 'success': false});
    final html = reportHtml(summary(exitCode: 1));
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('<img')));
    expect(html, contains('&lt;script&gt;'));
    expect(html, contains('a &amp; b'));
  });
}
