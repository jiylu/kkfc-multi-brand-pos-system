import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/pages/menu_screen.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_item_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/menu_states.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _meal = MenuItem(
  id: 'meal',
  name: 'Fixture Meal',
  description: 'Grilled chicken',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget child,
) async {
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1068, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  container.read(cartProvider.notifier).clear();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: counterTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  for (final availability in MenuAvailability.values) {
    testWidgets(
      'IT-MOB-MENU-001 Given ${availability.name} availability When tapping an item Then only available items enter the cart',
      (tester) async {
        final container = ProviderContainer();
        final item = MenuItem(
          id: _meal.id,
          name: _meal.name,
          description: _meal.description,
          pricesCentavos: _meal.pricesCentavos,
          availability: {MenuChannel.dineIn: availability},
        );
        await _pump(
          tester,
          container,
          Center(
            child: SizedBox(
              width: 300,
              child: MenuItemCard(item: item, channel: MenuChannel.dineIn),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_meal.name));
        await tester.pumpAndSettle();
        expect(
          container.read(cartCountProvider),
          availability == MenuAvailability.available ? 1 : 0,
        );
        final badge = switch (availability) {
          MenuAvailability.available => null,
          MenuAvailability.stockout => 'STOCKOUT',
          MenuAvailability.manualOff => 'MANUAL OFF',
          MenuAvailability.inactive => 'INACTIVE',
        };
        if (badge != null) expect(find.text(badge), findsOneWidget);
      },
    );
  }

  testWidgets(
    'IT-MOB-MENU-002 Given a pending menu When data arrives Then replace the skeleton with menu cards',
    (tester) async {
      final pending = Completer<List<MenuItem>>();
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) => pending.future)],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pump();
      expect(find.byType(MenuGridSkeleton), findsOneWidget);
      pending.complete([_meal]);
      await tester.pumpAndSettle();
      expect(find.byType(MenuGridSkeleton), findsNothing);
      expect(find.byType(MenuItemCard), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-MENU-003 Given a failed menu When retrying Then reload and display recovered data',
    (tester) async {
      var loads = 0;
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith((ref) async {
            loads++;
            if (loads == 1) throw StateError('Offline');
            return [_meal];
          }),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load the menu"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.byType(MenuItemCard), findsOneWidget);
    },
  );

  testWidgets(
    'IT-MOB-MENU-004 Given no search matches When clearing search Then restore menu cards and the search field',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          menuItemsProvider.overrideWith((ref) async => [_meal]),
        ],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'missing');
      await tester.pumpAndSettle();
      expect(find.text('No items match "missing"'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear search'));
      await tester.pumpAndSettle();
      expect(container.read(menuSearchProvider), isEmpty);
      expect(find.byType(MenuItemCard), findsOneWidget);
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).controller?.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'IT-MOB-MENU-005 Given an empty catalog When loading completes Then show an empty state without menu cards',
    (tester) async {
      final container = ProviderContainer(
        overrides: [menuItemsProvider.overrideWith((ref) async => [])],
      );
      await _pump(tester, container, const MenuScreen());
      await tester.pumpAndSettle();
      expect(find.byType(MenuMessageCard), findsOneWidget);
      expect(find.byType(MenuItemCard), findsNothing);
    },
  );
}
