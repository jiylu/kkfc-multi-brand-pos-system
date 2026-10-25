import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/widgets/kkfc_brand_tag.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge.dart';

/// "GrabFood  #GF-1001"
class KitchenTicketChannelLine extends StatelessWidget {
  const KitchenTicketChannelLine({
    super.key,
    required this.channel,
    required this.reference,
  });

  final String channel;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Wrap(
      spacing: KkfcSpace.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(channel, style: text.labelSmall?.copyWith(color: muted)),
        Text(
          reference,
          style: text.labelMedium?.copyWith(
            fontFamily: KkfcFonts.mono,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Status badge that cross-fades when the status changes.
class KitchenTicketStatusRow extends StatelessWidget {
  const KitchenTicketStatusRow({super.key, required this.status});

  final KkfcStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: KkfcMotion.base,
        child: KeyedSubtree(
          key: ValueKey(status),
          child: KkfcStatusBadge(status: status),
        ),
      ),
    );
  }
}

/// [AI] Aurelia's Inasal
class KitchenTicketBrandRow extends StatelessWidget {
  const KitchenTicketBrandRow({super.key, required this.brand});

  final AssignedBrand brand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KkfcBrandTag(label: brand.code),
        const SizedBox(width: KkfcSpace.s8),
        Expanded(
          child: Text(
            brand.name,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}