import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';

class MenuChannelNotifier extends Notifier<MenuChannel> {
  @override
  MenuChannel build() => MenuChannel.dineIn;
  void select(MenuChannel channel) => state = channel;
}

final menuChannelProvider = NotifierProvider<MenuChannelNotifier, MenuChannel>(
  MenuChannelNotifier.new,
);

class MenuSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
  void clear() => state = '';
}

final menuSearchProvider = NotifierProvider<MenuSearchNotifier, String>(
  MenuSearchNotifier.new,
);

final menuItemsProvider = FutureProvider.autoDispose<List<MenuItem>>((
  ref,
) async {
  ref.watch(activeBrandProvider); // refetch when the displayed brand changes
  final brandId = await ref.watch(authenticatedBrandIdProvider.future);
  return ref.watch(menuRepositoryProvider).getByBrand(brandId);
});

final visibleMenuItemsProvider =
    Provider.autoDispose<AsyncValue<List<MenuItem>>>((ref) {
      final query = ref.watch(menuSearchProvider).trim().toLowerCase();
      return ref
          .watch(menuItemsProvider)
          .whenData(
            (items) => query.isEmpty
                ? items
                : items
                      .where(
                        (i) =>
                            i.name.toLowerCase().contains(query) ||
                            i.description.toLowerCase().contains(query),
                      )
                      .toList(),
          );
    });

class CartNotifier extends Notifier<List<CartLine>> {
  /// Pre-filled to match the design. Change to `const []` for a real start.
  @override
  List<CartLine> build() => [
  ];

  void add(MenuItem item) {
    final i = state.indexWhere((l) => l.item.id == item.id);
    if (i == -1) {
      state = [...state, CartLine(item: item, quantity: 1)];
      return;
    }
    state = [
      for (var k = 0; k < state.length; k++)
        if (k == i)
          state[k].copyWith(quantity: state[k].quantity + 1)
        else
          state[k],
    ];
  }

  void decrement(String itemId) {
    state = [
      for (final l in state)
        if (l.item.id != itemId)
          l
        else if (l.quantity > 1)
          l.copyWith(quantity: l.quantity - 1),
    ];
  }

  void clear() => state = const [];
}

/// Not autoDispose: the draft order must survive tab changes.
/// TODO: clear on sign-out so the next cashier never sees it.
final cartProvider = NotifierProvider<CartNotifier, List<CartLine>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, l) => sum + l.quantity),
);

final cartTotalProvider = Provider<int>((ref) {
  final channel = ref.watch(menuChannelProvider);
  return ref
      .watch(cartProvider)
      .fold(0, (sum, l) => sum + l.totalCentavos(channel));
});
