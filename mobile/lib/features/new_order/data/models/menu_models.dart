// TODO: PALITA NG ACTUAL PARAMETERS FROM BACKEND

enum MenuChannel {
  dineIn('Dine-in', 'Table reference'),
  takeaway('Takeaway', 'Pickup reference'),
  grabFood('GrabFood', 'External order reference'),
  foodpanda('foodpanda', 'External order reference');

  const MenuChannel(this.label, this.referenceLabel);
  final String label;
  final String referenceLabel;
}

enum MenuAvailability { available, stockout, manualOff, inactive }

class ModifierOption {
  const ModifierOption({
    required this.id,
    required this.label,
    this.priceDeltaCentavos = 0,
  });

  final String id;
  final String label;
  final int priceDeltaCentavos;
}

/// Single-choice group (radio). Server data will define these later.
class ModifierGroup {
  const ModifierGroup({
    required this.id,
    required this.title,
    required this.options,
    required this.defaultOptionId,
    this.isAddOn = false,
  });

  /// Builds an optional add-on from a `menu_item_modifiers` row plus its
  /// modifier name. Modelled as an off/on group so cart pricing is unchanged.
  factory ModifierGroup.addOn({
    required String id,
    required String name,
    required int priceCentavos,
  }) => ModifierGroup(
    id: id,
    title: name,
    isAddOn: true,
    defaultOptionId: addOnOff,
    options: [
      const ModifierOption(id: addOnOff, label: 'None'),
      ModifierOption(
        id: addOnOn,
        label: name,
        priceDeltaCentavos: priceCentavos,
      ),
    ],
  );

  static const addOnOff = 'off';
  static const addOnOn = 'on';

  final String id;
  final String title;
  final List<ModifierOption> options;
  final String defaultOptionId;

  /// Rendered as a checkbox instead of a radio list.
  final bool isAddOn;

  ModifierOption optionById(String optionId) => options.firstWhere(
    (o) => o.id == optionId,
    orElse: () => options.firstWhere((o) => o.id == defaultOptionId),
  );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pricesCentavos,
    this.availability = const {},
    this.modifierGroups = const [],
    this.channels = const {},
  });

  final String id;
  final String name;
  final String description;
  final Map<MenuChannel, int> pricesCentavos;
  final Map<MenuChannel, MenuAvailability> availability;
  final List<ModifierGroup> modifierGroups;

  /// Channels the backend lists this item under (empty when unknown).
  final Set<MenuChannel> channels;

  MenuItem withModifierGroups(List<ModifierGroup> groups) => MenuItem(
    id: id,
    name: name,
    description: description,
    pricesCentavos: pricesCentavos,
    availability: availability,
    modifierGroups: groups,
    channels: channels,
  );

  /// Maps the `/menu-items/brand/:brandId` payload to the UI model.
  /// Monetary values are sent by Prisma as decimal JSON values (typically
  /// strings), so they are converted to integer centavos at this boundary.
  factory MenuItem.fromApiJson(Map<String, dynamic> json) {
    final id = json['menu_item_id'];
    final name = json['name'];
    final basePrice = json['base_price'];
    if (id is! String || name is! String || basePrice == null) {
      throw const FormatException('Menu item is missing required fields.');
    }

    final baseCentavos = decimalToCentavos(basePrice);
    final baseAvailable = json['is_available'] == true;
    final prices = <MenuChannel, int>{
      for (final channel in MenuChannel.values) channel: baseCentavos,
    };
    final availability = <MenuChannel, MenuAvailability>{
      for (final channel in MenuChannel.values)
        channel: baseAvailable
            ? MenuAvailability.available
            : MenuAvailability.stockout,
    };

    final channelRows = json['menu_item_channels_menu_item'];
    final listed = <MenuChannel>{};
    if (channelRows is List) {
      for (final row in channelRows) {
        if (row is! Map<String, dynamic>) continue;
        final channel = _menuChannelFromApi(row['order_channel']);
        final price = row['price'];
        if (channel == null || price == null) continue;
        listed.add(channel);
        prices[channel] = decimalToCentavos(price);
        availability[channel] = baseAvailable && row['is_available'] == true
            ? MenuAvailability.available
            : MenuAvailability.manualOff;
      }
    }

    return MenuItem(
      id: id,
      name: name,
      description: json['description'] as String? ?? '',
      pricesCentavos: prices,
      availability: availability,
      channels: listed,
    );
  }

  int priceFor(MenuChannel channel) =>
      pricesCentavos[channel] ?? pricesCentavos[MenuChannel.dineIn] ?? 0;

  MenuAvailability availabilityFor(MenuChannel channel) =>
      availability[channel] ?? MenuAvailability.available;
}

MenuChannel? _menuChannelFromApi(Object? value) => switch (value) {
  'DINE_IN' => MenuChannel.dineIn,
  'TAKEAWAY' => MenuChannel.takeaway,
  'GRABFOOD' => MenuChannel.grabFood,
  'FOODPANDA' => MenuChannel.foodpanda,
  _ => null,
};

int decimalToCentavos(Object value) {
  final text = value.toString();
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) throw FormatException('Invalid monetary value: $text');
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
}

String formatPesoDelta(int centavos) =>
    centavos < 0 ? '−${formatPeso(-centavos)}' : '+${formatPeso(centavos)}';

/// Sum of price changes for a set of selections.
int modifiersCentavosFor(MenuItem item, Map<String, String> selections) {
  var sum = 0;
  for (final g in item.modifierGroups) {
    sum += g.optionById(selections[g.id] ?? g.defaultOptionId).priceDeltaCentavos;
  }
  return sum;
}

class CartLine {
  const CartLine({
    required this.id,
    required this.item,
    required this.quantity,
    this.selections = const {},
  });

  final String id;
  final MenuItem item;
  final int quantity;
  final Map<String, String> selections; // groupId -> optionId

  CartLine copyWith({int? quantity, Map<String, String>? selections}) =>
      CartLine(
        id: id,
        item: item,
        quantity: quantity ?? this.quantity,
        selections: selections ?? this.selections,
      );

  int unitCentavos(MenuChannel channel) =>
      item.priceFor(channel) + modifiersCentavosFor(item, selections);

  int totalCentavos(MenuChannel channel) => unitCentavos(channel) * quantity;

  /// Only choices that differ from the default, so a plain line shows nothing.
  List<String> get modifierSummary {
    final out = <String>[];
    for (final g in item.modifierGroups) {
      final id = selections[g.id] ?? g.defaultOptionId;
      if (id == g.defaultOptionId) continue;
      final o = g.optionById(id);
      out.add(
        o.priceDeltaCentavos == 0
            ? o.label
            : '${o.label} ${formatPesoDelta(o.priceDeltaCentavos)}',
      );
    }
    return out;
  }
}

String formatPeso(int centavos) {
  final pesos = (centavos ~/ 100).toString();
  final cents = (centavos % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < pesos.length; i++) {
    if (i > 0 && (pesos.length - i) % 3 == 0) buf.write(',');
    buf.write(pesos[i]);
  }
  return '₱$buf.$cents';
}