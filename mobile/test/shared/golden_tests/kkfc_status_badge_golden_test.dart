import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge.dart';

import '../../support/golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadGoldenFonts);

  for (final viewport in goldenViewports) {
    for (final textScale in goldenTextScales) {
      testWidgets('gallery at ${viewport.name} and ${textScale}x text', (
        tester,
      ) async {
        await pumpGoldenSheet(
          tester,
          viewport: viewport,
          textScale: textScale,
          child: Wrap(
            spacing: KkfcSpace.s8,
            runSpacing: KkfcSpace.s8,
            children: [
              for (final status in KkfcStatus.values)
                KkfcStatusBadge(status: status),
            ],
          ),
        );

        _expectLightTheme(tester);
        expect(
          find.byType(KkfcStatusBadge),
          findsNWidgets(KkfcStatus.values.length),
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(goldenSheetKey),
          matchesGoldenFile(
            goldenPath(
              component: 'kkfc_status_badge',
              state: 'gallery',
              viewport: viewport,
              textScale: textScale,
            ),
          ),
        );
      });
    }
  }
}

void _expectLightTheme(WidgetTester tester) {
  final context = tester.element(find.byType(KkfcStatusBadge).first);
  expect(Theme.of(context).brightness, Brightness.light);
  expect(Theme.of(context).colorScheme, counterTheme.colorScheme);
}
