import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/availability/presentation/pages/availability_read_only_screen.dart';
import 'package:mobile/features/availability/providers/availability_providers.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _activeItem = MenuItem(
  id: 'active',
  name: 'Paa Inasal',
  description: 'Grilled chicken',
  pricesCentavos: {MenuChannel.dineIn: 18900},
  availability: {
    MenuChannel.dineIn: MenuAvailability.available,
    MenuChannel.takeaway: MenuAvailability.stockout,
    MenuChannel.grabFood: MenuAvailability.manualOff,
    MenuChannel.foodpanda: MenuAvailability.available,
  },
);

const _inactiveItem = MenuItem(
  id: 'inactive',
  name: 'Batchoy Special',
  description: 'Noodles',
  pricesCentavos: {MenuChannel.dineIn: 14900},
  availability: {
    MenuChannel.dineIn: MenuAvailability.inactive,
    MenuChannel.takeaway: MenuAvailability.inactive,
    MenuChannel.grabFood: MenuAvailability.inactive,
    MenuChannel.foodpanda: MenuAvailability.inactive,
  },
);

Future<void> _pump(
  WidgetTester tester,
  Future<List<MenuItem>> Function() load,
) async {
  tester.view.physicalSize = const Size(1068, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        menuItemsProvider.overrideWith((ref) async => const <MenuItem>[]),
        availabilityMenuItemsProvider.overrideWith((ref) => load()),
      ],
      child: MaterialApp(
        theme: counterTheme,
        home: const AvailabilityReadOnlyScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'IT-MOB-AVAIL-003 Given backend menu items When opening availability Then list every item with Dine-in status and inactive state',
    (tester) async {
      await _pump(tester, () async => [_activeItem, _inactiveItem]);
      await tester.pumpAndSettle();

      expect(find.text('Paa Inasal · Dine-in'), findsOneWidget);
      expect(find.text('Batchoy Special · Dine-in'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-AVAIL-004 Given per-channel availability When selecting Takeaway Then show Takeaway availability',
    (tester) async {
      await _pump(tester, () async => [_activeItem, _inactiveItem]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Takeaway'));
      await tester.pumpAndSettle();

      expect(find.text('Paa Inasal · Dine-in'), findsNothing);
      expect(find.text('Paa Inasal · Takeaway'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-AVAIL-005 Given a pending availability request When data arrives Then replace the loading state with rows',
    (tester) async {
      final pending = Completer<List<MenuItem>>();
      await _pump(tester, () => pending.future);
      await tester.pump();

      expect(find.text('Loading availability'), findsOneWidget);

      pending.complete([_activeItem]);
      await tester.pumpAndSettle();

      expect(find.text('Loading availability'), findsNothing);
      expect(find.text('Paa Inasal · Dine-in'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-AVAIL-006 Given a failed availability request When retrying Then reload and show rows',
    (tester) async {
      var loads = 0;
      await _pump(tester, () async {
        loads++;
        if (loads == 1) throw StateError('Offline');
        return [_activeItem];
      });
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load availability"), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(loads, 2);
      expect(find.text('Paa Inasal · Dine-in'), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-AVAIL-007 Given a brand with no menu items When opening availability Then show an empty state',
    (tester) async {
      await _pump(tester, () async => const <MenuItem>[]);
      await tester.pumpAndSettle();

      expect(find.text('No menu items'), findsOneWidget);
      expect(
        find.text('This brand has no menu items to show.'),
        findsOneWidget,
      );
    },
  );
}
