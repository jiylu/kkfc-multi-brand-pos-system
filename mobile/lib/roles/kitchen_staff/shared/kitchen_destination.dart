import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

enum KitchenDestination {
  newOrder('New order', Symbols.add_circle),
  orders('Orders', Symbols.receipt_long),
  menu('Menu', Symbols.restaurant);

  const KitchenDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}
