import 'dart:convert';

import 'gherkin_scenarios.dart';

/// Interprets Dart's JSON test protocol, including errors after testDone.
class IntegrationReport {
  final Map<int, Map<String, dynamic>> _tests = {};
  bool? runnerSuccess;
  bool completed = false;

  void addLine(String line) {
    dynamic event;
    try {
      event = jsonDecode(line);
    } on FormatException {
      return; // Flutter also writes build/device diagnostics outside the protocol.
    }
    if (event is! Map<String, dynamic>) return;
    final id = event['testID'] ?? event['test']?['id'];
    switch (event['type']) {
      case 'testStart':
        final test = event['test'] as Map<String, dynamic>;
        final record = _record(test['id'] as int);
        record['name'] = test['name'];
        record['startedMs'] = event['time'];
      case 'error':
        if (id is! int) return;
        final record = _record(id);
        (record['errors'] as List).add({
          'message': event['error'],
          'stackTrace': event['stackTrace'],
        });
        record['status'] = 'Failed';
        record['hidden'] = false;
      case 'testDone':
        if (id is! int) return;
        final record = _record(id);
        final hasErrors = (record['errors'] as List).isNotEmpty;
        record['hidden'] = event['hidden'] == true && !hasErrors;
        record['status'] = hasErrors || event['result'] != 'success'
            ? 'Failed'
            : event['skipped'] == true
            ? 'Skipped'
            : 'Passed';
        final start = record['startedMs'];
        if (start is num && event['time'] is num) {
          record['durationMs'] = (event['time'] as num) - start;
        }
      case 'done':
        completed = true;
        runnerSuccess = event['success'] as bool?;
    }
  }

  Map<String, dynamic> _record(int id) => _tests.putIfAbsent(
    id,
    () => <String, dynamic>{
      'id': id,
      'name': 'Test $id',
      'status': 'Not completed',
      'hidden': false,
      'errors': <Map<String, dynamic>>[],
    },
  );

  Map<String, dynamic> summarize({
    required int exitCode,
    required DateTime started,
    required DateTime finished,
    required List<String> arguments,
    String? launchError,
    List<Map<String, String>> scenarios = const [],
  }) {
    final tests = <Map<String, dynamic>>[];
    final blockers = <String>[];
    if (launchError != null) blockers.add(launchError);
    for (final record in _tests.values) {
      if (record['hidden'] == true) continue;
      final lifecycle = RegExp(r'^(loading |\(setUpAll\)|\(tearDownAll\))')
          .hasMatch(record['name'] as String);
      if (lifecycle) {
        if (record['status'] != 'Passed') {
          blockers.add('${record['name']}: ${jsonEncode(record['errors'])}');
        }
        continue;
      }
      tests.add(Map<String, dynamic>.from(record));
    }
    int count(String status) =>
        tests.where((t) => t['status'] == status).length;
    if (!completed) {
      blockers.add(
        'Flutter did not finish a test run. Check run.log for device, build, '
        'configuration, or process errors.',
      );
    }
    if (tests.isEmpty) blockers.add('No test cases were executed.');
    if (exitCode != 0 && count('Failed') == 0 && blockers.isEmpty) {
      blockers.add('Flutter exited with code $exitCode. See run.log.');
    }
    if (runnerSuccess != true && count('Failed') == 0 && blockers.isEmpty) {
      blockers.add('The test runner did not report success. See run.log.');
    }
    final status = count('Failed') > 0
        ? 'Failed'
        : blockers.isNotEmpty || count('Not completed') > 0
        ? 'Blocked'
        : count('Passed') > 0
        ? 'Passed'
        : 'Skipped';
    return {
      'status': status,
      'started': started.toIso8601String(),
      'finished': finished.toIso8601String(),
      'durationMs': finished.difference(started).inMilliseconds,
      'exitCode': exitCode,
      'arguments': arguments,
      'counts': {
        for (final status in ['Passed', 'Failed', 'Skipped', 'Not completed'])
          status: count(status),
      },
      'tests': tests,
      'scenarios': scenarioResults(scenarios, tests),
      'blockers': blockers,
    };
  }
}

String reportHtml(Map<String, dynamic> report) {
  String escape(Object? value) => const HtmlEscape().convert('$value');
  final tests = report['tests'] as List;
  final blockers = report['blockers'] as List;
  final failures = tests.where((t) => t['status'] == 'Failed');
  final scenarios = report['scenarios'] as List? ?? [];
  String errors(dynamic test) => (test['errors'] as List)
      .map((e) => '${e['message']}\n${e['stackTrace']}')
      .join('\n\n');
  return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Flutter integration test report</title>
<style>
body{font:16px/1.5 system-ui,sans-serif;max-width:1080px;margin:40px auto;padding:0 20px;color:#172333;background:#f5f7fa}
section{background:white;border:1px solid #cbd5e1;border-radius:10px;padding:20px;margin:20px 0}
h1,h2{line-height:1.2}table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:12px;border-bottom:1px solid #cbd5e1;vertical-align:top}
pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eef2f6;padding:12px;font-size:13px}
.Passed{color:#146332}.Failed{color:#a51d24}.Blocked{color:#805500}a{color:#174ea6}
</style></head><body>
<h1>Flutter integration test report</h1>
<h2 class="${escape(report['status'])}">${escape(report['status'])}</h2>
<p>Started: ${escape(report['started'])}<br>Finished: ${escape(report['finished'])}<br>
Duration: ${escape(((report['durationMs'] as num) / 1000).toStringAsFixed(1))} seconds · Exit code: ${escape(report['exitCode'])}</p>
<p>${(report['counts'] as Map).entries.map((e) => '${escape(e.key)}: ${escape(e.value)}').join(' · ')}</p>
<p><a href="run.log">Full execution log</a> · <a href="results.json">Structured results</a></p>
<section><h2>Test results</h2><table><thead><tr><th>Test</th><th>Result</th><th>Duration</th></tr></thead><tbody>
${tests.map((t) => '<tr><td>${escape(t['name'])}</td><td class="${escape(t['status'])}">${escape(t['status'])}</td><td>${escape(t['durationMs'] ?? '—')} ms</td></tr>').join('\n')}
</tbody></table>${tests.isEmpty ? '<p>No test cases were executed.</p>' : ''}</section>
<section><h2>Gherkin scenarios</h2>
<p><a href="auth-api.integration.feature">Gherkin file with scenario results</a></p>
<p>Results apply to each complete scenario. Individual steps are descriptions; Flutter does not report separate step results.</p>
${scenarios.map((s) => '<h3>${escape(s['id'])} — ${escape(s['status'])}</h3><pre>${escape(s['gherkin'])}</pre>').join('\n')}
${scenarios.isEmpty ? '<p>No scenarios were mapped.</p>' : ''}</section>
<section><h2>Failures to investigate</h2>
<p>Failures are observed test problems, not confirmed application bugs. Review the assertions, API availability, test data, and logs before assigning a cause.</p>
${failures.isEmpty ? '<p>No failed test cases were recorded.</p>' : failures.map((t) => '<h3>${escape(t['name'])}</h3><pre>${escape(errors(t))}</pre>').join('\n')}
</section><section><h2>Run blockers</h2>
${blockers.isEmpty ? '<p>No run blockers were recorded.</p>' : blockers.map((b) => '<pre>${escape(b)}</pre>').join('\n')}
</section></body></html>''';
}
