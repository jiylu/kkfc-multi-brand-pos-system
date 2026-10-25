import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/availability/presentation/pages/availability_management_screen.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_toggle.dart';

void main() {
  testWidgets(
    'IT-MOB-AVAIL-001 Given sample availability When toggling one row Then change only that row and its semantics',
    (tester) async {
      tester.view.physicalSize = const Size(1068, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: counterTheme,
            home: const AvailabilityManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final toggles = find.byType(AvailabilityToggle);
      final before = tester
          .widgetList<AvailabilityToggle>(toggles)
          .map((toggle) => toggle.value)
          .toList();
      expect(before, isNotEmpty);
      final first = tester.widget<AvailabilityToggle>(toggles.first);
      final label = first.semanticLabel;
      final switchFinder = find.descendant(
        of: toggles.first,
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      final after = tester
          .widgetList<AvailabilityToggle>(toggles)
          .map((toggle) => toggle.value)
          .toList();
      expect(after.first, !before.first);
      expect(after.skip(1), before.skip(1));
      final semantics = tester.widget<Semantics>(
        find
            .descendant(of: toggles.first, matching: find.byType(Semantics))
            .first,
      );
      expect(semantics.properties.label, label);
      expect(semantics.properties.toggled, !before.first);
      expect(
        find.descendant(
          of: toggles.first,
          matching: find.text(before.first ? 'Off' : 'On'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'IT-MOB-AVAIL-002 Given a narrow phone with enlarged text When opening availability Then render without overflow and allow scrolling to toggles',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: counterTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const AvailabilityManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(AvailabilityToggle).last);
    },
  );
}
