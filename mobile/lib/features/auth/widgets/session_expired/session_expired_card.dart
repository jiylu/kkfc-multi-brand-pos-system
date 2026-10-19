import 'package:flutter/material.dart';

import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'session_expired_copy.dart';
import 'session_expired_layout.dart';
import 'session_expired_motion.dart';

/// Presentational card. No controller or session logic, so it can be
/// previewed and widget-tested on its own.
class SessionExpiredCard extends StatelessWidget {
  const SessionExpiredCard({
    super.key,
    required this.motion,
    required this.compact,
    required this.itemLabel,
    required this.onSignIn,
  });

  final SessionExpiredMotion motion;
  final bool compact;
  final String itemLabel;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final inner = compact ? SessionExpiredLayout.gapLg : SessionExpiredLayout.gapXl;

    return FadeTransition(
      opacity: motion.cardIn,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(motion.cardIn),
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KkfcRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScaleTransition(
                scale: motion.accentGrow,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: KkfcBorderWidth.thick,
                  color: semantic.warning.border,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(inner),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionEndedEyebrow, style: KkfcTypography.caption),
                    const SizedBox(height: SessionExpiredLayout.gapXs),
                    Semantics(
                      header: true,
                      child: Text(sessionExpiredTitle,
                          style: KkfcTypography.headline),
                    ),
                    const SizedBox(height: SessionExpiredLayout.gapSm),
                    Text(sessionExpiredBody(itemLabel),
                        style: KkfcTypography.body),
                    const SizedBox(height: SessionExpiredLayout.gapLg),
                    ScaleTransition(
                      scale: motion.pillPop,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: semantic.success.bg,
                          borderRadius: BorderRadius.circular(KkfcRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SessionExpiredLayout.gapMd,
                            vertical: SessionExpiredLayout.gapSm,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_rounded,
                                  size: KkfcSizing.iconSm,
                                  color: semantic.success.fg),
                              const SizedBox(width: SessionExpiredLayout.gapSm),
                              Expanded(
                                child: Text(cartPreservedLabel(itemLabel),
                                    style: KkfcTypography.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SessionExpiredLayout.gapLg),
                    SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: SessionExpiredLayout.minTouchTarget,
                        ),
                        child: FilledButton(
                          onPressed: onSignIn,
                          child: Text(signInAgainLabel,
                              style: KkfcTypography.labelLg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}