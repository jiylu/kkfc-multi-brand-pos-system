import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/presentation/widgets/animated_peso.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';

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
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: MenuSpace.md),
          KkfcLoadingButton(
            label: 'Check and send',
            loadingLabel: 'Sending…',
            isLoading: false, // TODO: wire to the real sending state once the backend exists.
            onPressed: canSend ? onSend : null,
          ),
          const SizedBox(height: MenuSpace.sm),
          Text(
            'Review item prices and modifiers before sending.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
