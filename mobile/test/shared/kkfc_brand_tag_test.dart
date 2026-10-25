import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/widgets/kkfc_brand_tag.dart';

void main() {
  testWidgets('shows the label and a placeholder when no logo is given',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: counterTheme,
        home: const Scaffold(body: KkfcBrandTag(label: 'Gamcheon')),
      ),
    );

    expect(find.byType(KkfcBrandTag), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('does not overflow at large text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: counterTheme,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 240,
              child: KkfcBrandTag(label: "Aurelia's Inasal"),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}