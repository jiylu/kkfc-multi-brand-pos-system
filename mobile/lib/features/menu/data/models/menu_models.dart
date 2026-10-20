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

  int priceFor(MenuChannel channel) =>
      pricesCentavos[channel] ?? pricesCentavos[MenuChannel.dineIn] ?? 0;

  MenuAvailability availabilityFor(MenuChannel channel) =>
      availability[channel] ?? MenuAvailability.available;
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