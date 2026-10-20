import 'package:flutter/material.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/animated_peso.dart';

class CartPanelFooter extends StatelessWidget {
  const CartPanelFooter({
    super.key,
    required this.count,
    required this.total,
    required this.canSend,
    required this.onSend,
  });

  final int count;
  final int total;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(MenuSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Total · $count items', style: text.titleSmall),
              ),
              AnimatedPeso(
                centavos: total,
                style:
                    text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: MenuSpace.md),
          FilledButton(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            // TODO: submit order once the backend exists.
            onPressed: canSend ? onSend : null,
            child: const Text('Check and send'),
          ),
          const SizedBox(height: MenuSpace.sm),
          Text('Review item prices and modifiers before sending.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
