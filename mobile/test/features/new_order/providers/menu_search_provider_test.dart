import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _items = [
  MenuItem(
    id: 'chicken',
    name: 'Chicken Meal',
    description: 'Grilled favorite',
    pricesCentavos: {},
  ),
  MenuItem(
    id: 'rice',
    name: 'Rice',
    description: 'Steamed side',
    pricesCentavos: {},
  ),
];

void main() {
  for (final query in [' CHICKEN ', ' grilled ']) {
    test(
      'UT-MOB-SEARCH-001 Given menu data When searching "$query" Then match names or descriptions ignoring case and whitespace',
      () async {
        final container = ProviderContainer(
          overrides: [menuItemsProvider.overrideWith((ref) async => _items)],
        );
        addTearDown(container.dispose);
        container.listen(visibleMenuItemsProvider, (_, _) {});
        await container.read(menuItemsProvider.future);
        container.read(menuSearchProvider.notifier).set(query);
        expect(
          container
              .read(visibleMenuItemsProvider)
              .requireValue
              .map((item) => item.id),
          ['chicken'],
        );
        container.read(menuSearchProvider.notifier).clear();
        expect(container.read(visibleMenuItemsProvider).requireValue, _items);
      },
    );
  }

  test('UT-MOB-SEARCH-002 Given a pending menu When loading fails Then propagate loading and error instead of empty results', () async {
    final pending = Completer<List<MenuItem>>();
    final container = ProviderContainer(
      overrides: [menuItemsProvider.overrideWith((ref) => pending.future)],
    );
    addTearDown(container.dispose);
    container.listen(visibleMenuItemsProvider, (_, _) {});
    expect(container.read(visibleMenuItemsProvider).isLoading, isTrue);
    final error = StateError('Menu offline');
    final future = container.read(menuItemsProvider.future);
    final assertion = expectLater(future, throwsA(same(error)));
    pending.completeError(error);
    await assertion;
    expect(container.read(visibleMenuItemsProvider).error, same(error));
  });
}
