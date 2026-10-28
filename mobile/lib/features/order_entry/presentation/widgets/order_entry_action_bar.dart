import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'order_entry_shadows.dart';

class OrderEntryActionBar extends StatelessWidget {
  const OrderEntryActionBar({
    super.key,
    this.secondaryLabel,
    required this.primaryLabel,
    this.isLoading = false,
    this.onSecondary,
    this.onPrimary,
    this.sideBySide = false,
  });

  final String? secondaryLabel;
  final String primaryLabel;
  final bool isLoading;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;
  final bool sideBySide;

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
            final narrow = c.maxWidth < 480;
            final hasSecondary =
                secondaryLabel != null && secondaryLabel!.trim().isNotEmpty;

            final primary = KkfcLoadingButton(
              label: primaryLabel,
              loadingLabel: 'Sending...',
              isLoading: isLoading,
              onPressed: onPrimary,
            );

            if (!hasSecondary) {
              if (narrow) {
                return primary;
              }
              return Row(
                children: [
                  SizedBox(width: 300, child: primary),
                ],
              );
            }

            final secondary = OutlinedButton(
              onPressed: isLoading ? null : onSecondary,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, KkfcSizing.controlLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KkfcRadius.sm),
                ),
              ),
              child: Text(secondaryLabel!),
            );

            // Two buttons on one row (Order confirmed).
            if (sideBySide) {
              if (narrow) {
                return Row(
                  children: [
                    Expanded(child: secondary),
                    const SizedBox(width: KkfcSpace.s16),
                    Expanded(child: primary),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 200, child: secondary),
                  const SizedBox(width: KkfcSpace.s16),
                  SizedBox(width: 200, child: primary),
                ],
              );
            }

            // Default (Check before sending): stacked on narrow, row on wide.
            if (narrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  primary,
                  const SizedBox(height: KkfcSpace.s8),
                  secondary,
                ],
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