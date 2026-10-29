/// Reads the tagged, plain scenarios used by the authentication test suite.
/// This maps descriptions to Flutter results; it does not execute Gherkin steps.
List<Map<String, String>> readAuthScenarios(String source) {
  final scenarios = <Map<String, String>>[];
  String? feature;
  String? pendingId;
  Map<String, String>? current;
  for (final line in source.split('\n')) {
    final text = line.trim();
    if (text.isEmpty || text.startsWith('#')) continue;
    if (text.startsWith('@')) {
      pendingId = RegExp(r'@([A-Z]+-MOB-(?:AUTH|POS)-\d+)\b')
          .firstMatch(text)
          ?.group(1);
    } else if (text.startsWith('Feature:')) {
      feature = text.substring('Feature:'.length).trim();
    } else if (text.startsWith('Scenario:')) {
      if (feature == null || pendingId == null) {
        throw const FormatException(
          'Each auth scenario needs a feature and test ID tag.',
        );
      }
      if (scenarios.any((s) => s['id'] == pendingId)) {
        throw FormatException('Duplicate scenario tag: $pendingId');
      }
      current = {
        'id': pendingId,
        'feature': feature,
        'name': text.substring('Scenario:'.length).trim(),
        'gherkin': text,
      };
      scenarios.add(current);
      pendingId = null;
    } else if (RegExp(r'^(Given|When|Then|And|But)\s').hasMatch(text) &&
        current != null) {
      current['gherkin'] = '${current['gherkin']}\n  $text';
    } else {
      throw FormatException('Unsupported auth scenario syntax: $text');
    }
  }
  if (scenarios.isEmpty ||
      scenarios.any((s) => !s['gherkin']!.contains('\n'))) {
    throw const FormatException(
      'Expected auth scenarios with Given/When/Then steps.',
    );
  }
  return scenarios;
}

List<Map<String, dynamic>> scenarioResults(
  List<Map<String, String>> scenarios,
  List<Map<String, dynamic>> tests,
) => scenarios.map((scenario) {
  final id = scenario['id']!;
  final matching = tests
      .where(
        (test) =>
            RegExp('(^|\\s)${RegExp.escape(id)}(\\s|\$)')
                .hasMatch(test['name'] as String),
      )
      .toList();
  final statuses = matching.map((test) => test['status']).toSet();
  final status = matching.isEmpty
      ? 'Not run'
      : statuses.contains('Failed')
      ? 'Failed'
      : statuses.contains('Not completed')
      ? 'Not completed'
      : statuses.every((status) => status == 'Passed')
      ? 'Passed'
      : statuses.every((status) => status == 'Skipped')
      ? 'Skipped'
      : 'Partially skipped';
  return <String, dynamic>{
    ...scenario,
    'status': status,
    'tests': matching.map((test) => test['name']).toList(),
  };
}).toList();

/// Result comments preserve valid, shareable Gherkin without inventing step results.
String gherkinWithResults(Map<String, dynamic> report) {
  final scenarios = report['scenarios'] as List;
  final buffer = StringBuffer('# Run result: ${report['status']}\n');
  if (scenarios.isNotEmpty) {
    buffer.writeln('Feature: ${scenarios.first['feature']}');
  }
  for (final scenario in scenarios) {
    buffer.writeln('\n  # Result: ${scenario['status']}');
    if (scenario['category'] != null) {
      buffer.writeln(
        '  @${(scenario['category'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      );
    }
    buffer.writeln('  @${scenario['id']}');
    for (final line in (scenario['gherkin'] as String).split('\n')) {
      buffer.writeln('  $line');
    }
  }
  return buffer.toString();
}
