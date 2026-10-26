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

/// Replace with the server value later.
const int kExtraRiceCentavos = 2500;

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pricesCentavos,
    this.availability = const {},
  });

  final String id;
  final String name;
  final String description;
  final Map<MenuChannel, int> pricesCentavos;
  final Map<MenuChannel, MenuAvailability> availability;

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

    final baseCentavos = _decimalToCentavos(basePrice);
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
    if (channelRows is List) {
      for (final row in channelRows) {
        if (row is! Map<String, dynamic>) continue;
        final channel = _menuChannelFromApi(row['order_channel']);
        final price = row['price'];
        if (channel == null || price == null) continue;
        prices[channel] = _decimalToCentavos(price);
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

int _decimalToCentavos(Object value) {
  final text = value.toString();
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) throw FormatException('Invalid monetary value: $text');
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
}

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    this.extraRice = false,
  });

  final MenuItem item;
  final int quantity;
  final bool extraRice;

  CartLine copyWith({int? quantity}) => CartLine(
    item: item,
    quantity: quantity ?? this.quantity,
    extraRice: extraRice,
  );

  int unitCentavos(MenuChannel channel) =>
      item.priceFor(channel) + (extraRice ? kExtraRiceCentavos : 0);

  int totalCentavos(MenuChannel channel) => unitCentavos(channel) * quantity;
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
