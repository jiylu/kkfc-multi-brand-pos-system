import 'dart:convert';
import 'dart:io';

import 'integration_report.dart';
import 'gherkin_scenarios.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Run from mobile/: dart run tool/run_integration_tests.dart -d <device-id>\n'
      'Use --suite=pos for the separate Login -> Brand/Channel -> Menu -> Cart suite.\n'
      'Additional Flutter test arguments are forwarded. The default config is\n'
      'env/test-emulator.json unless you supply any --dart-define option.\n'
      'Reports: reports/integration/<timestamp>/report.html, results.json, run.log',
    );
    return;
  }
  final started = DateTime.now().toUtc();
  final suiteOptions = args.where((arg) => arg.startsWith('--suite=')).toList();
  final suite = suiteOptions.isEmpty
      ? 'auth'
      : suiteOptions.single.substring('--suite='.length);
  final forwarded = args.where((arg) => !arg.startsWith('--suite=')).toList();
  final isPos = suite == 'pos';
  final featureFile = isPos
      ? 'pos-core.integration.feature'
      : 'auth-api.integration.feature';
  final directory = Directory.fromUri(
    Platform.script.resolve(
      '../reports/integration/${started.toIso8601String().replaceAll(':', '-')}/',
    ),
  );
  await directory.create(recursive: true);
  final log = File('${directory.path}/run.log').openWrite();
  final report = IntegrationReport();
  final arguments = [
    'test',
    isPos
        ? 'integration_test/pos_core_test.dart'
        : 'integration_test/auth_api_test.dart',
    if (!forwarded.any((arg) => arg.startsWith('--dart-define')))
      '--dart-define-from-file=${isPos ? '.fixtures/pos-flow.json' : 'env/test-emulator.json'}',
    ...forwarded,
    '--machine',
  ];
  var resultCode = 1;
  String? launchError;
  var scenarios = <Map<String, String>>[];
  try {
    if (suite != 'auth' && suite != 'pos') {
      throw ArgumentError('Choose --suite=auth or --suite=pos.');
    }
    scenarios = readAuthScenarios(
      await File.fromUri(
        Platform.script.resolve('../../features/mobile/$featureFile'),
      ).readAsString(),
    );
    if (!args.contains('-d') &&
        !args.contains('--device-id') &&
        !args.any((a) => a.startsWith('--device-id=') || a.startsWith('-d='))) {
      throw ArgumentError('Specify a device with -d <device-id>.');
    }
    final process = await Process.start(
      'flutter',
      arguments,
      workingDirectory: Directory.fromUri(Platform.script.resolve('../')).path,
      runInShell: Platform.isWindows,
    );
    // Drain both streams concurrently to prevent a full pipe blocking Flutter.
    Future<void> consume(Stream<List<int>> stream, IOSink console) async {
      await for (final line
          in stream.transform(utf8.decoder).transform(const LineSplitter())) {
        console.writeln(line);
        log.writeln(line);
        report.addLine(line);
      }
    }

    await Future.wait([
      consume(process.stdout, stdout),
      consume(process.stderr, stderr),
    ]);
    resultCode = await process.exitCode;
  } catch (error) {
    launchError = error.toString();
    log.writeln(launchError);
    stderr.writeln(launchError);
  } finally {
    await log.flush();
    await log.close();
  }
  final summary = report.summarize(
    exitCode: resultCode,
    started: started,
    finished: DateTime.now().toUtc(),
    arguments: arguments,
    launchError: launchError,
    scenarios: scenarios,
  );
  summary['gherkinFile'] = featureFile;
  if (isPos) summary['title'] = 'Mobile POS core flow integration test report';
  await File('${directory.path}/$featureFile')
      .writeAsString(gherkinWithResults(summary));
  await File('${directory.path}/results.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
  final html = File('${directory.path}/report.html');
  await html.writeAsString(reportHtml(summary));
  stdout.writeln('\n${summary['status']} — Report: ${html.absolute.path}');
  exitCode = resultCode != 0
      ? resultCode
      : summary['status'] == 'Passed' || summary['status'] == 'Skipped'
      ? 0
      : 1;
}
