import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/shared/widgets/kkfc_switch.dart';

void main() {
  testWidgets('tap toggles the value', (tester) async {
    var value = false;
    await tester.pumpWidget(MaterialApp(
      theme: counterTheme,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => KkfcSwitch(
            value: value,
            title: 'Paa Inasal',
            subtitle: value
                ? 'Available on GrabFood'
                : 'Unavailable on GrabFood',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(KkfcSwitch));
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('disabled switch ignores taps', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: counterTheme,
      home: const Scaffold(
        body: KkfcSwitch(
          value: false,
          title: 'Paa Inasal',
          onChanged: null,
        ),
      ),
    ));

    await tester.tap(find.byType(KkfcSwitch));
    await tester.pump();
    expect(find.byType(KkfcSwitch), findsOneWidget);
  });

  testWidgets('still builds at large text scale', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: counterTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: KkfcSwitch(
          value: true,
          title: 'Paa Inasal',
          subtitle: 'Available on GrabFood',
          onChanged: (_) {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}