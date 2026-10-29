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
    overrides: [
      assignedBrandsProvider.overrideWithValue(_brands),
      assignedBrandProvider.overrideWith((ref) async => _brands[0]),
    ],
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

Future<void> _continue(WidgetTester tester) async {
  final button = find.text('Continue with selected brand');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'IT-MOB-BRAND-001 Given a populated cart When continuing with the only assigned brand Then preserve brand and cart',
    (tester) async {
      final container = await _pump(tester);
      final before = container.read(cartProvider);
      await _continue(tester);
      expect(find.text('Clear cart & switch'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
      expect(container.read(cartProvider), same(before));
    },
  );

  testWidgets(
    'IT-MOB-BRAND-002 Given an assigned brand When opening the picker Then show no demo brands',
    (tester) async {
      final container = await _pump(tester);
      expect(find.text('Brand A'), findsWidgets);
      expect(find.text('Brand B'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
    },
  );

  testWidgets(
    'IT-MOB-BRAND-003 Given the current brand When continuing without a different selection Then preserve the cart without confirmation',
    (tester) async {
      final container = await _pump(tester);
      final before = container.read(cartProvider);
      await _continue(tester);
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
    'IT-MOB-BRAND-005 Given an empty cart When continuing with the assigned brand Then do not switch menus',
    (tester) async {
      final container = await _pump(tester, empty: true);
      await _continue(tester);
      expect(find.text('Clear cart & switch'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
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
      expect(find.text('Clear cart & switch'), findsNothing);
      expect(container.read(activeBrandProvider).id, 'a');
      expect(tester.takeException(), isNull);
    },
  );
}
