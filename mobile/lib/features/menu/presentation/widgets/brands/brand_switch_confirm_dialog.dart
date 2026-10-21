import 'package:flutter/material.dart';
import 'package:mobile/features/menu/data/models/brand_models.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/menu_dialog.dart';

// Unapproved policy copy from the design review. Remove once Product +
// Backend confirm the switch/reset behavior.
const _proposalTitle = 'PO REVIEW PROPOSAL — NOT APPROVED';
const _proposalBody =
    'Do not discard a cart automatically. Confirm the final '
    'switch/reset policy with Product + Backend.';

/// Returns true to clear the cart and switch, false/null to keep the order.
Future<bool?> showBrandSwitchConfirm(
  BuildContext context, {
  required AssignedBrand current,
  required AssignedBrand target,
  required int cartCount,
}) {
  return showMenuDialog<bool>(
    context,
    builder: (_) =>
        _ConfirmContent(current: current, target: target, cartCount: cartCount),
  );
}

class _ConfirmContent extends StatelessWidget {
  const _ConfirmContent({
    required this.current,
    required this.target,
    required this.cartCount,
  });

  final AssignedBrand current;
  final AssignedBrand target;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final items = cartCount == 1 ? 'item' : 'items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Switch to ${target.name}?',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: MenuSpace.sm),
        Text(
          'Current cart: $cartCount $items for ${current.name}. '
          'Switching brands may clear the existing order.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: MenuSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(MenuRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MenuSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _proposalTitle,
                  style: text.labelSmall?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: MenuSpace.xs),
                Text(
                  _proposalBody,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MenuSpace.lg),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MenuRadius.md),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep current order'),
        ),
        const SizedBox(height: MenuSpace.sm),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Clear cart & switch · proposed'),
        ),
      ],
    );
  }
}
