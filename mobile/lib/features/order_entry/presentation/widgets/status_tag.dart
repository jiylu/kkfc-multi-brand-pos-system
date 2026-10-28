import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/tokens.dart';

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.text,
    required this.tone,
    this.icon,
  });

  final String text;
  final KkfcTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KkfcSpace.s16,
          vertical: KkfcSpace.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: tone.fg),
              const SizedBox(width: KkfcSpace.s4),
            ],
            Flexible(
              child: Text(
                text.toUpperCase(),
                style: t.labelMedium?.copyWith(
                  color: tone.fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}