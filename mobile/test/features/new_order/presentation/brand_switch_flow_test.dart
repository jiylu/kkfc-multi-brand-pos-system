import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/brand_switch_flow.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _brands = [
  AssignedBrand(id: 'a', code: 'AA', name: 'Brand A'),
  AssignedBrand(id: 'b', code: 'BB', name: 'Brand B'),
];
const _meal = MenuItem(
  id: 'meal',
  name: 'Meal',
  description: '',
  pricesCentavos: {MenuChannel.dineIn: 10000},
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool empty = false,
  Size size = const Size(800, 1000),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [assignedBrandsProvider.overrideWithValue(_brands)],
  );
  addTearDown(container.dispose);
  container.read(activeBrandProvider.notifier).select(_brands[0]);
  container.read(cartProvider.notifier).clear();
  if (!empty) container.read(cartProvider.notifier).add(_meal);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: counterTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: FilledButton(
                onPressed: () => startBrandSwitch(context, ref),
                child: const Text('Switch brand'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Switch brand'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _continue(WidgetTester tester, {bool target = true}) async {
  if (target) {
    await tester.tap(find.text('BB · Brand B'));
    await tester.pumpAndSettle();
  }
  final button = find.text('Continue with selected brand');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'IT-MOB-BRAND-001 Given a populated cart When cancelling a brand switch Then preserve brand and cart',
    (tester) async {
      final container = await _pump(tester);
      final before = container.read(cartProvider);
      await _continue(tester);
      expect(find.text('Switch to Brand B?'), findsOneWidget);
      await tester.tap(find.text('Keep current order'));
      await tester.pumpAndSettle();
      expect(container.read(activeBrandProvider).id, 'a');
      expect(container.read(cartProvider), same(before));
    },
  );

  testWidgets(
    'IT-MOB-BRAND-002 Given a populated cart When confirming a brand switch Then select the target and clear the cart',
    (tester) async {
      final container = await _pump(tester);
      await _continue(tester);
      await tester.tap(find.text('Clear cart & switch'));
      await tester.pumpAndSettle();
      expect(container.read(activeBrandProvider).id, 'b');
      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalProvider), 0);
    },
  );

  testWidgets(
    'IT-MOB-BRAND-003 Given the current brand When continuing without a different selection Then preserve the cart without confirmation',
    (tester) async {
      final container = await _pump(tester);
      final before = container.read(cartProvider);
      await _continue(tester, target: false);
      expect(find.text('Clear cart & switch'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
      expect(container.read(cartProvider), same(before));
    },
  );

  testWidgets(
    'IT-MOB-BRAND-004 Given the brand picker When dismissed Then preserve brand and cart',
    (tester) async {
      final container = await _pump(tester);
      final before = container.read(cartProvider);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text('Choose assigned brand'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
      expect(container.read(cartProvider), same(before));
    },
  );

  testWidgets(
    'IT-MOB-BRAND-005 Given an empty cart When switching brand Then skip confirmation and invalidate the menu',
    (tester) async {
      final container = await _pump(tester, empty: true);
      container.listen(menuItemsProvider, (_, _) {});
      final before = container.read(menuItemsProvider.future);
      await tester.pump(const Duration(seconds: 1));
      await _continue(tester);
      expect(find.text('Clear cart & switch'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'b');
      expect(container.read(menuItemsProvider.future), isNot(same(before)));
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'IT-MOB-BRAND-006 Given a narrow phone at enlarged text When switching brand Then keep both dialogs scrollable and controls reachable',
    (tester) async {
      final container = await _pump(
        tester,
        size: const Size(320, 900),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await _continue(tester);
      expect(tester.takeException(), isNull);
      final confirm = find.text('Clear cart & switch');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(container.read(activeBrandProvider).id, 'b');
      expect(tester.takeException(), isNull);
    },
  );
}
