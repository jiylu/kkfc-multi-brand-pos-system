import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

const _meal = MenuItem(
  id: 'meal',
  name: 'Meal',
  description: 'Grilled chicken',
  pricesCentavos: {MenuChannel.dineIn: 10000, MenuChannel.grabFood: 12000},
);

final _extraRice = ModifierGroup.addOn(
  id: 'extra-rice',
  name: 'Extra rice',
  priceCentavos: 2500,
);

final _mealWithRice = _meal.withModifierGroups([_extraRice]);

class _ModifiedCart extends CartNotifier {
  @override
  List<CartLine> build() => [
    CartLine(
      id: 'line-test',
      item: _mealWithRice,
      quantity: 2,
      selections: {_extraRice.id: ModifierGroup.addOnOn},
    ),
  ];
}

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer();
    container.read(cartProvider.notifier).clear();
  });
  tearDown(() => container.dispose());

  test('UT-MOB-CART-001 Given an empty cart When adding an item twice Then merge quantities without mutating earlier state', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(_meal);
    final first = container.read(cartProvider);
    expect(first.single.quantity, 1);
    cart.add(_meal);
    expect(container.read(cartProvider).single.quantity, 2);
    expect(first.single.quantity, 1);
    expect(container.read(cartCountProvider), 2);
    expect(container.read(cartTotalProvider), 20000);
  });

  test('UT-MOB-CART-002 Given two units When decrementing Then remove the final unit and ignore unknown IDs', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(_meal);
    cart.add(_meal);
    cart.decrementLine('unknown');
    expect(container.read(cartProvider).single.quantity, 2);
    cart.decrementLine(container.read(cartProvider).first.id);
    expect(container.read(cartProvider).single.quantity, 1);
    cart.decrementLine(container.read(cartProvider).first.id);
    expect(container.read(cartProvider), isEmpty);
    expect(container.read(cartCountProvider), 0);
    expect(container.read(cartTotalProvider), 0);
  });

  test('UT-MOB-CART-003 Given a populated cart When clearing Then reset lines count and total without mutating the previous cart', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(_meal);
    final before = container.read(cartProvider);
    cart.clear();
    expect(container.read(cartProvider), isEmpty);
    expect(container.read(cartCountProvider), 0);
    expect(container.read(cartTotalProvider), 0);
    expect(before.single.item.id, _meal.id);
  });

  test('UT-MOB-CART-004 Given quantities and extra rice When changing channel Then recalculate exact centavos and preserve modifiers', () {
    final modified = ProviderContainer(
      overrides: [cartProvider.overrideWith(_ModifiedCart.new)],
    );
    addTearDown(modified.dispose);
    final before = modified.read(cartProvider);
    expect(modified.read(cartTotalProvider), 25000);
    modified.read(menuChannelProvider.notifier).select(MenuChannel.grabFood);
    expect(modified.read(cartTotalProvider), 29000);
    expect(modified.read(cartCountProvider), 2);
    expect(modified.read(cartProvider), same(before));
    expect(
      modified.read(cartProvider).single.selections[_extraRice.id],
      ModifierGroup.addOnOn,
    );
    expect(modified.read(cartProvider).single.modifierSummary, [
      'Extra rice +₱25.00',
    ]);
  });

  for (final entry in {
    0: '₱0.00',
    1: '₱0.01',
    99: '₱0.99',
    100: '₱1.00',
    123456: '₱1,234.56',
  }.entries) {
    test(
      'UT-MOB-MONEY-001 Given ${entry.key} centavos When formatting Then return ${entry.value}',
      () {
        expect(formatPeso(entry.key), entry.value);
      },
    );
  }
}
