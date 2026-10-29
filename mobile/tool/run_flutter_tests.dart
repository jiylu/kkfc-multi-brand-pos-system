import 'dart:convert';
import 'dart:io';

import 'flutter_suite_report.dart';
import 'gherkin_scenarios.dart';
import 'integration_report.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Run from mobile/: dart run tool/run_flutter_tests.dart [--coverage]\n'
      'Runs test/ only and saves HTML, JSON, Gherkin, and the raw execution log\n'
      'under reports/flutter/<timestamp>/. Additional Flutter options are forwarded.',
    );
    return;
  }
  final root = Directory.fromUri(Platform.script.resolve('../'));
  final started = DateTime.now().toUtc();
  final output = Directory.fromUri(
    root.uri.resolve(
      'reports/flutter/${started.toIso8601String().replaceAll(':', '-')}/',
    ),
  );
  await output.create(recursive: true);
  final log = File.fromUri(output.uri.resolve('run.log')).openWrite();
  final report = IntegrationReport();
  final arguments = ['test', 'test', ...args, '--machine'];
  var code = 1;
  String? launchError;
  try {
    final process = await Process.start(
      'flutter',
      arguments,
      workingDirectory: root.path,
      runInShell: Platform.isWindows,
    );
    Future<void> consume(Stream<List<int>> stream, IOSink console) async {
      await for (final line
          in stream.transform(utf8.decoder).transform(const LineSplitter())) {
        log.writeln(line);
        console.writeln(line);
        report.addLine(line);
      }
    }

    await Future.wait([
      consume(process.stdout, stdout),
      consume(process.stderr, stderr),
    ]);
    code = await process.exitCode;
  } catch (error) {
    launchError = error.toString();
    log.writeln(launchError);
    stderr.writeln(launchError);
  } finally {
    await log.flush();
    await log.close();
  }
  final summary = report.summarize(
    exitCode: code,
    started: started,
    finished: DateTime.now().toUtc(),
    arguments: arguments,
    launchError: launchError,
  );
  final contents = <String, String>{};
  for (final test in summary['tests'] as List) {
    final path = test['source'] as String?;
    if (path != null && !contents.containsKey(path)) {
      final file = path.startsWith('file:')
          ? File.fromUri(Uri.parse(path))
          : File(path);
      if (await file.exists()) contents[path] = await file.readAsString();
    }
  }
  describeFlutterSuite(summary, contents);
  await File.fromUri(output.uri.resolve('results.json'))
      .writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
  await File.fromUri(output.uri.resolve('test-results.feature'))
      .writeAsString(gherkinWithResults(summary));
  final html = File.fromUri(output.uri.resolve('report.html'));
  await html.writeAsString(reportHtml(summary));
  stdout.writeln('\n${summary['status']} — Report: ${html.absolute.path}');
  exitCode = code != 0
      ? code
      : ['Passed', 'Skipped'].contains(summary['status'])
      ? 0
      : 1;
}
