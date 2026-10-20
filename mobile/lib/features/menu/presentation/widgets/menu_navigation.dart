import 'package:flutter/material.dart';

const _destinations = [
  (icon: Icons.add_shopping_cart_outlined, selected: Icons.add_shopping_cart, label: 'New order'),
  (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: 'Orders'),
  (icon: Icons.restaurant_menu_outlined, selected: Icons.restaurant_menu, label: 'Menu'),
  (icon: Icons.history_outlined, selected: Icons.history, label: 'Audit'),
];

class MenuRail extends StatelessWidget {
  const MenuRail({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NavigationRail(
      backgroundColor: scheme.inverseSurface,
      selectedIndex: 0,
      labelType: NavigationRailLabelType.all,
      // TODO: route between tabs once Orders / Audit screens exist.
      onDestinationSelected: (_) {},
      selectedIconTheme: IconThemeData(color: scheme.inverseSurface),
      unselectedIconTheme: IconThemeData(color: scheme.onInverseSurface),
      selectedLabelTextStyle: TextStyle(color: scheme.onInverseSurface),
      unselectedLabelTextStyle: TextStyle(color: scheme.onInverseSurface.withValues(alpha: 0.7)),
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selected),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class MenuBottomNav extends StatelessWidget {
  const MenuBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NavigationBar(
      backgroundColor: scheme.inverseSurface,
      indicatorColor: scheme.onInverseSurface.withValues(alpha: 0.12),
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: [
        for (final d in _destinations)
          NavigationDestination(
            icon: Icon(d.icon, color: scheme.onInverseSurface.withValues(alpha: 0.7)),
            selectedIcon: Icon(d.selected, color: scheme.onInverseSurface),
            label: d.label,
            tooltip: d.label,
          ),
      ],
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: scheme.onInverseSurface);
        }
        return TextStyle(color: scheme.onInverseSurface.withValues(alpha: 0.7));
      }),
    );
  }
}