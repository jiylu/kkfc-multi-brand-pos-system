import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class CartLineTile extends ConsumerWidget {
  const CartLineTile({super.key, required this.line, required this.channel});

  final CartLine line;
  final MenuChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final modifier = line.extraRice
        ? 'Plain rice · Extra rice +${formatPeso(kExtraRiceCentavos)}'
        : 'Plain rice';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MenuSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: MenuSpace.sm),
              Text(
                formatPeso(line.totalCentavos(channel)),
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  modifier,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Remove one',
                onPressed: () =>
                    ref.read(cartProvider.notifier).decrement(line.item.id),
                icon: const Icon(Icons.remove),
              ),
              AnimatedSwitcher(
                duration: context.motion(MenuMotion.fast),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Padding(
                  key: ValueKey(line.quantity),
                  padding: const EdgeInsets.symmetric(horizontal: MenuSpace.md),
                  child: Text('${line.quantity}', style: text.titleSmall),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Add one',
                onPressed: () => ref.read(cartProvider.notifier).add(line.item),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: MenuSpace.md),
        ],
      ),
    );
  }
}
