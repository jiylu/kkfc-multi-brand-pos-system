import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'order_entry_shadows.dart';

class OrderEntryActionBar extends StatelessWidget {
  const OrderEntryActionBar({
    super.key,
    required this.secondaryLabel,
    required this.primaryLabel,
    this.onSecondary,
    this.onPrimary,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: OrderEntryShadows.bar(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KkfcSpace.s16),
        child: LayoutBuilder(
          builder: (context, c) {
            final secondary = OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, KkfcSizing.controlLg),
              ),
              child: Text(secondaryLabel),
            );
            final primary = KkfcLoadingButton(
              label: primaryLabel,
              loadingLabel: 'Sending...',
              isLoading: true,
              onPressed: onPrimary,
            );

            // Narrow: stacked and full width. Wide: left-aligned row.
            if (c.maxWidth < 480) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [primary, const SizedBox(height: KkfcSpace.s8), secondary],
              );
            }
            return Row(
              children: [
                secondary,
                const SizedBox(width: KkfcSpace.s16),
                Flexible(child: primary),
              ],
            );
          },
        ),
      ),
    );
  }
}