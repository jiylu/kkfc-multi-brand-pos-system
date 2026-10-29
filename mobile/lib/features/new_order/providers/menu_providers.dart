import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:flutter/foundation.dart' show mapEquals;

class MenuChannelNotifier extends Notifier<MenuChannel> {
  MenuChannel? _previous;

  @override
  MenuChannel build() {
    _previous = null;
    return MenuChannel.dineIn;
  }

  MenuChannel? get previousChannel => _previous;

  void select(MenuChannel channel) {
    if (channel == state) return;
    _previous = state;
    state = channel;
  }

  bool undo() {
    final previous = _previous;
    if (previous == null || previous == state) return false;
    _previous = state;
    state = previous;
    return true;
  }

  void reset() {
    _previous = null;
    state = MenuChannel.dineIn;
  }
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

class OrderReferenceNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String reference) => state = reference;
  void clear() => state = '';
}

final orderReferenceProvider = NotifierProvider<OrderReferenceNotifier, String>(
  OrderReferenceNotifier.new,
);

class StoreReferenceNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String reference) => state = reference;
  void clear() => state = '';
}

final storeReferenceProvider = NotifierProvider<StoreReferenceNotifier, String>(
  StoreReferenceNotifier.new,
);

final menuItemsProvider = FutureProvider.autoDispose<List<MenuItem>>((
  ref,
) async {
  ref.watch(activeBrandProvider); // refetch when the displayed brand changes
  final brandId = await ref.watch(authenticatedBrandIdProvider.future);
  return ref.watch(menuRepositoryProvider).getByBrand(brandId);
});

/// Channels to show as tabs: those the loaded menu items are sold on, in
/// [MenuChannel] order. Falls back to every channel while the menu is
/// loading, on error, or when the backend lists no channels.
final availableChannelsProvider = Provider.autoDispose<List<MenuChannel>>((
  ref,
) {
  final items = ref.watch(menuItemsProvider).asData?.value;
  if (items == null) return MenuChannel.values;
  final listed = {for (final item in items) ...item.channels};
  if (listed.isEmpty) return MenuChannel.values;
  return [
    for (final channel in MenuChannel.values)
      if (listed.contains(channel)) channel,
  ];
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
  int _seq = 0;

  @override
  List<CartLine> build() => const [];

  /// Fills in the default option for any group that has no selection.
  Map<String, String> _normalize(MenuItem item, Map<String, String> s) => {
    for (final g in item.modifierGroups) g.id: s[g.id] ?? g.defaultOptionId,
  };

  int _findIdentical(
    MenuItem item,
    Map<String, String> sel, {
    String? except,
  }) => state.indexWhere(
    (l) =>
        l.id != except && l.item.id == item.id && mapEquals(l.selections, sel),
  );

  /// Quick add with defaults (no modifiers).
  void add(MenuItem item) => addConfigured(item, const {}, 1);

  void addConfigured(
    MenuItem item,
    Map<String, String> selections,
    int quantity,
  ) {
    final sel = _normalize(item, selections);
    final i = _findIdentical(item, sel);
    if (i != -1) {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i)
            state[k].copyWith(quantity: state[k].quantity + quantity)
          else
            state[k],
      ];
      return;
    }
    state = [
      ...state,
      CartLine(
        id: 'line-${_seq++}',
        item: item,
        quantity: quantity,
        selections: sel,
      ),
    ];
  }

  void updateLine(
    String lineId,
    Map<String, String> selections,
    int quantity, {
    MenuItem? item,
  }) {
    final i = state.indexWhere((l) => l.id == lineId);
    if (i == -1) return;
    final line = item == null
        ? state[i]
        : CartLine(
            id: state[i].id,
            item: item,
            quantity: state[i].quantity,
            selections: state[i].selections,
          );
    final sel = _normalize(line.item, selections);

    // If the edit makes this line identical to another, merge them.
    final j = _findIdentical(line.item, sel, except: lineId);
    if (j != -1) {
      final otherId = state[j].id;
      state = [
        for (final l in state)
          if (l.id != lineId)
            (l.id == otherId ? l.copyWith(quantity: l.quantity + quantity) : l),
      ];
      return;
    }
    state = [
      for (final l in state)
        if (l.id == lineId)
          CartLine(
            id: line.id,
            item: line.item,
            quantity: quantity,
            selections: sel,
          )
        else
          l,
    ];
  }

  void incrementLine(String lineId) => state = [
    for (final l in state)
      if (l.id == lineId) l.copyWith(quantity: l.quantity + 1) else l,
  ];

  void decrementLine(String lineId) => state = [
    for (final l in state)
      if (l.id != lineId)
        l
      else if (l.quantity > 1)
        l.copyWith(quantity: l.quantity - 1),
  ];

  void clear() => state = const [];
}

/// Not autoDispose: the draft order must survive tab changes.
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
