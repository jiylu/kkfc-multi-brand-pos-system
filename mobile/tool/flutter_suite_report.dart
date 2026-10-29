/// Classifies a test file by the test APIs it declares, not its filename alone.
String categoryForTestSource(String source) {
  if (RegExp(r'^\s*goldenTest\s*\(', multiLine: true).hasMatch(source)) {
    return 'Golden';
  }
  final widget = RegExp(
    r'^\s*testWidgets\s*\(',
    multiLine: true,
  ).hasMatch(source);
  final unit = RegExp(r'^\s*test\s*\(', multiLine: true).hasMatch(source);
  if (widget && unit) return 'Unit / widget';
  if (widget) return 'Widget';
  return unit ? 'Unit' : 'Unclassified';
}

/// Creates one descriptive scenario per observed test, including loop variants.
/// This does not imply that Gherkin steps were independently executed.
void describeFlutterSuite(
  Map<String, dynamic> report,
  Map<String, String> sourceContents,
) {
  final tests = (report['tests'] as List).cast<Map<String, dynamic>>();
  final scenarios = <Map<String, dynamic>>[];
  for (final test in tests) {
    final source = test['source'] as String? ?? 'Unknown test file';
    final category = categoryForTestSource(sourceContents[source] ?? '');
    test['category'] = category;
    final name = (test['name'] as String).replaceAll(RegExp(r'[\r\n]+'), ' ');
    final path = source.replaceAll('\\', '/');
    final testIndex = path.lastIndexOf('/test/');
    final displayPath = testIndex >= 0 ? path.substring(testIndex + 1) : path;
    // Stable across parallel execution order and identical names in other files.
    var hash = 0x811c9dc5;
    for (final byte in '$displayPath\n$name'.codeUnits) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    final id = 'CASE-${hash.toRadixString(16).padLeft(8, '0')}';
    final businessSteps = RegExp(
      r'\bGiven\s+(.+?)\s+When\s+(.+?)\s+Then\s+(.+)$',
    ).firstMatch(name);
    final steps = businessSteps != null
        ? '  Given ${businessSteps.group(1)}\n'
              '  When ${businessSteps.group(2)}\n'
              '  Then ${businessSteps.group(3)}'
        : category == 'Golden'
        ? '  Given the golden fixture in "$displayPath"\n'
              '  When "$name" is rendered with its configured viewport and text scale\n'
              '  Then the rendered image should match its configured golden baseline'
        : '  Given the ${category.toLowerCase()} test fixtures in "$displayPath"\n'
              '  When the test "$name" is executed\n'
              '  Then its declared assertions should hold';
    scenarios.add({
      'id': id,
      'feature': 'Flutter unit, widget, and golden tests',
      'name': name,
      'category': category,
      'gherkin': 'Scenario: $name\n$steps',
      'status': test['status'],
      'tests': [name],
    });
  }
  report['title'] = 'Flutter unit, widget, and golden test report';
  report['gherkinFile'] = 'test-results.feature';
  report['scenarioNote'] =
      'These scenario descriptions are generated from test '
      'names and fixtures. Given/When/Then wording is preserved when present in '
      'the test name; other scenarios describe the test harness and assertions.';
  report['scenarios'] = scenarios;
  final categories = {
    'Unit',
    'Widget',
    'Golden',
    ...tests.map((t) => t['category'] as String),
  };
  report['categoryCounts'] = {
    for (final category in categories)
      category: {
        for (final status in ['Passed', 'Failed', 'Skipped', 'Not completed'])
          status: tests
              .where((t) => t['category'] == category && t['status'] == status)
              .length,
      },
  };
}
