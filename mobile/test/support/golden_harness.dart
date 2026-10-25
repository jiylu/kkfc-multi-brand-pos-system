import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

class GoldenViewport {
  const GoldenViewport({required this.name, required this.size});

  final String name;
  final Size size;
}

const goldenViewports = [
  GoldenViewport(name: '360dp', size: Size(360, 800)),
  GoldenViewport(name: '720dp', size: Size(720, 1280)),
  GoldenViewport(name: '1280dp', size: Size(1280, 800)),
];

const goldenTextScales = [1.0, 2.0];

const goldenBoundaryKey = ValueKey<String>('golden-boundary');
const goldenSheetKey = ValueKey<String>('golden-sheet');

Future<void> loadGoldenFonts() async {
  await _loadFontFamily(KkfcFonts.text, const [
    'assets/fonts/Atkinson_Hyperlegible_Next/AtkinsonHyperlegibleNext-Regular.ttf',
    'assets/fonts/Atkinson_Hyperlegible_Next/AtkinsonHyperlegibleNext-Medium.ttf',
    'assets/fonts/Atkinson_Hyperlegible_Next/AtkinsonHyperlegibleNext-SemiBold.ttf',
    'assets/fonts/Atkinson_Hyperlegible_Next/AtkinsonHyperlegibleNext-Bold.ttf',
  ]);
  await _loadFontFamily(KkfcFonts.numeric, const [
    'assets/fonts/IBM_Plex_Sans_Condensed/IBMPlexSansCondensed-Medium.ttf',
    'assets/fonts/IBM_Plex_Sans_Condensed/IBMPlexSansCondensed-SemiBold.ttf',
    'assets/fonts/IBM_Plex_Sans_Condensed/IBMPlexSansCondensed-Bold.ttf',
  ]);
  await _loadFontFamily(KkfcFonts.mono, const [
    'assets/fonts/Atkinson_Hyperlegible_Mono/AtkinsonHyperlegibleMono-Medium.ttf',
    'assets/fonts/Atkinson_Hyperlegible_Mono/AtkinsonHyperlegibleMono-SemiBold.ttf',
  ]);
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

Future<void> pumpGolden(
  WidgetTester tester, {
  required GoldenViewport viewport,
  required double textScale,
  required Widget child,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: counterTheme,
      themeMode: ThemeMode.light,
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: TickerMode(enabled: false, child: appChild!),
        );
      },
      home: RepaintBoundary(
        key: goldenBoundaryKey,
        child: ColoredBox(
          color: counterTheme.scaffoldBackgroundColor,
          child: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(KkfcSpace.s24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpGoldenSheet(
  WidgetTester tester, {
  required GoldenViewport viewport,
  required double textScale,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(viewport.size.width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: counterTheme,
      themeMode: ThemeMode.light,
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: TickerMode(enabled: false, child: appChild!),
        );
      },
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: goldenSheetKey,
          child: SizedBox(
            width: viewport.size.width,
            child: ColoredBox(
              color: counterTheme.scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(KkfcSpace.s24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

String goldenPath({
  required String component,
  required String state,
  required GoldenViewport viewport,
  required double textScale,
}) {
  final scale = textScale.toStringAsFixed(1).replaceAll('.', '_');
  final width = viewport.name.replaceAll('dp', '');
  return 'goldens/$component/$state/${width}dp-text-$scale.png';
}
