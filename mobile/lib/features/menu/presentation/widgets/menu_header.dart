import 'package:flutter/material.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/channel_tabs.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({super.key, required this.compact});

  /// True on phones: brand and user on one row, tabs on a second row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final brand = OutlinedButton.icon(
      // TODO: open the "Choose assigned brand" dialog.
      onPressed: () {},
      icon: const Icon(Icons.expand_more),
      iconAlignment: IconAlignment.end,
      label: const Text("Aurelia's Inasal"),
    );

    final user = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ana R.', style: text.labelLarge),
        Text('Order staff',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );

    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MenuSpace.md),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [brand, const Spacer(), user]),
                    const SizedBox(height: MenuSpace.md),
                    const ChannelTabs(),
                  ],
                )
              : Row(
                  children: [
                    brand,
                    const SizedBox(width: MenuSpace.lg),
                    const Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ChannelTabs(),
                      ),
                    ),
                    const SizedBox(width: MenuSpace.lg),
                    user,
                  ],
                ),
        ),
      ),
    );
  }
}