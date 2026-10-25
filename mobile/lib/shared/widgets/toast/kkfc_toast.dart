import 'package:flutter/material.dart';

import 'package:mobile/shared/data/models/kkfc_toast_metrics.dart';
import 'kkfc_toast_style.dart';
import 'package:mobile/shared/data/models/kkfc_toast_tone.dart';

/// The toast visual. Use it inline, or via [KkfcToaster] for overlay toasts.
class KkfcToast extends StatelessWidget {
  const KkfcToast({
    super.key,
    required this.message,
    this.tone = KkfcToastTone.success,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.expand = false,
    this.elevated = false,
    this.entrance,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'actionLabel and onAction must be given together',
        );

  final String message;
  final KkfcToastTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Fill the available width (phones) instead of hugging the content.
  final bool expand;

  /// Adds a shadow. Used when floating over content.
  final bool elevated;

  /// Drives the icon pop-in. Null means no icon motion.
  final Animation<double>? entrance;

  @override
  Widget build(BuildContext context) {
    final style = KkfcToastStyle.resolve(context, tone);
    final theme = Theme.of(context);
    final iconSize =
        MediaQuery.textScalerOf(context).scale(KkfcToastMetrics.iconSize);
    final hasAction = actionLabel != null;

    Widget iconWidget = ExcludeSemantics(
      child: Icon(
        icon ?? KkfcToastStyle.defaultIcon(tone),
        size: iconSize,
        color: style.foreground,
        fill: 1,
      ),
    );
    if (entrance != null) {
      iconWidget = ScaleTransition(
        scale: entrance!.drive(
          Tween<double>(begin: 0.5, end: 1).chain(
            CurveTween(
              curve: const Interval(0.35, 1, curve: Curves.easeOutBack),
            ),
          ),
        ),
        child: iconWidget,
      );
    }

    final text = Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(color: style.foreground),
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: style.background,
        elevation: elevated ? KkfcToastMetrics.floatingElevation : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KkfcToastMetrics.radius),
          side: BorderSide(
            color: style.border,
            width: KkfcToastMetrics.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: KkfcToastMetrics.minHeight),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: KkfcToastMetrics.paddingX,
              end: hasAction
                  ? KkfcToastMetrics.paddingEndWithAction
                  : KkfcToastMetrics.paddingX,
              top: KkfcToastMetrics.paddingY,
              bottom: KkfcToastMetrics.paddingY,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconWidget,
                SizedBox(width: KkfcToastMetrics.gap),
                expand ? Expanded(child: text) : Flexible(child: text),
                if (hasAction) ...[
                  SizedBox(width: KkfcToastMetrics.gap),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: style.action,
                      minimumSize: KkfcToastMetrics.actionMinSize,
                      padding: const EdgeInsets.symmetric(
                        horizontal: KkfcToastMetrics.actionPaddingX,
                      ),
                      textStyle: theme.textTheme.labelLarge,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}