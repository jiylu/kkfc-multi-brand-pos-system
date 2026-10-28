import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/app/theme/tokens.dart';

class ToneNotice extends StatelessWidget {
  const ToneNotice({
    super.key,
    this.title,
    required this.body,
    required this.tone,
  });

  final String? title;
  final String body;
  final KkfcTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasTitle = title != null && title!.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(KkfcRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KkfcSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTitle) ...[
                Text(
                  title!.toUpperCase(),
                  style: text.labelMedium?.copyWith(
                    color: tone.fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: KkfcSpace.s4),
              ],
              Text(
                body,
                style: (hasTitle ? text.bodySmall : text.bodyMedium)?.copyWith(
                  color: tone.fg,
                  fontWeight: hasTitle ? null : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}