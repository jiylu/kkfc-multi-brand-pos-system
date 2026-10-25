import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

import '../../support/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadGoldenFonts);

  for (final viewport in goldenViewports) {
    for (final textScale in goldenTextScales) {
      testWidgets('idle at ${viewport.name} and ${textScale}x text', (
        tester,
      ) async {
        await _pumpButton(tester, viewport: viewport, textScale: textScale);

        _expectLightTheme(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(goldenBoundaryKey),
          matchesGoldenFile(
            goldenPath(
              component: 'kkfc_loading_button',
              state: 'idle',
              viewport: viewport,
              textScale: textScale,
            ),
          ),
        );
      });

      testWidgets('loading at ${viewport.name} and ${textScale}x text', (
        tester,
      ) async {
        await _pumpButton(
          tester,
          viewport: viewport,
          textScale: textScale,
          isLoading: true,
        );

        _expectLightTheme(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(goldenBoundaryKey),
          matchesGoldenFile(
            goldenPath(
              component: 'kkfc_loading_button',
              state: 'loading',
              viewport: viewport,
              textScale: textScale,
            ),
          ),
        );
      });
    }
  }
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required GoldenViewport viewport,
  required double textScale,
  bool isLoading = false,
}) {
  return pumpGolden(
    tester,
    viewport: viewport,
    textScale: textScale,
    child: SizedBox(
      width: double.infinity,
      child: KkfcLoadingButton(
        label: 'Sign in',
        loadingLabel: 'Signing in…',
        isLoading: isLoading,
        onPressed: _noop,
      ),
    ),
  );
}

void _expectLightTheme(WidgetTester tester) {
  final context = tester.element(find.byType(KkfcLoadingButton));
  expect(Theme.of(context).brightness, Brightness.light);
  expect(Theme.of(context).colorScheme, counterTheme.colorScheme);
}

void _noop() {}
