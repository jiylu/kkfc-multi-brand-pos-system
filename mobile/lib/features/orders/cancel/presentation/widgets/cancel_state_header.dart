import 'package:flutter/material.dart';

import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/shared/shared_layout.dart';

import 'cancel_tone.dart';

/// Banner pill, page title and the status icon tile (design frames 10-15).
class CancelStateHeader extends StatelessWidget {
  const CancelStateHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final CancelOrderStep step;
  final String title;
  final String subtitle;

  IconData get _icon => switch (step) {
    CancelOrderStep.review => Icons.warning_amber_rounded,
    CancelOrderStep.reasonRequired => Icons.close_rounded,
    CancelOrderStep.approvalRequired => Icons.warning_amber_rounded,
    CancelOrderStep.processing => Icons.sync,
    CancelOrderStep.cancelled => Icons.check_rounded,
    CancelOrderStep.denied => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CancelBanner(label: step.bannerLabel, tone: step.tone),
              SizedBox(height: MenuSpace.md),
              Text(
                title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: MenuSpace.xs),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(width: MenuSpace.md),
        CancelStatusIcon(icon: _icon, tone: step.iconTone),
      ],
    );
  }
}

/// Uppercase pill that labels the current stage of the workflow.
class CancelBanner extends StatelessWidget {
  const CancelBanner({super.key, required this.label, required this.tone});

  final String label;
  final CancelTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = cancelTone(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuSpace.md,
        vertical: MenuSpace.xs,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// 56x56 rounded tile that mirrors the icon column in the designs.
class CancelStatusIcon extends StatelessWidget {
  const CancelStatusIcon({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 56,
  });

  final IconData icon;
  final CancelTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final KkfcTone colors = cancelTone(context, tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(MenuRadius.lg),
      ),
      child: Icon(icon, color: colors.fg, size: size / 2),
    );
  }
}
