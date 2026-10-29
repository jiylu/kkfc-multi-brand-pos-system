import 'package:flutter/material.dart';

import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Labelled switch row. Pass `onChanged: null` to disable it.
class KkfcSwitch extends StatefulWidget {
  const KkfcSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.autofocus = false,
    this.compact = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;

  /// Optional second line, for example "Available on GrabFood".
  final String? subtitle;
  final bool autofocus;
  final bool compact;

  @override
  State<KkfcSwitch> createState() => _KkfcSwitchState();
}

class _KkfcSwitchState extends State<KkfcSwitch> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final focusColor =
        context.semanticColors.borderFocus; // verify the real name

    final disabledInk = scheme.onSurface.withValues(
      alpha: KkfcOpacity.disabled,
    );

    // Track and thumb colors per state
    final Color track;
    final Color trackBorder;
    final Color thumb;
    if (!_enabled) {
      track = disabledInk;
      trackBorder = disabledInk;
      thumb = widget.value
          ? scheme.surface
          : scheme.onSurface.withValues(alpha: KkfcOpacity.disabled * 2);
    } else if (widget.value) {
      track = scheme.primary;
      trackBorder = scheme.primary;
      thumb = scheme.surface;
    } else {
      track = _pressed
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainer;
      trackBorder = (_hovered || _pressed) ? scheme.onSurface : scheme.outline;
      thumb = scheme.outline;
    }

    final titleStyle = textTheme.bodyMedium?.copyWith(
      color: _enabled ? scheme.onSurface : disabledInk,
    );
    final subtitleStyle = textTheme.bodySmall?.copyWith(
      color: _enabled ? scheme.onSurfaceVariant : disabledInk,
    );

    // The thumb stretches a little while pressed
    final thumbBase = widget.compact ? 36.0 : KkfcSizing.thumb;
    final thumbWidth = thumbBase * (_pressed && _enabled ? 1.2 : 1.0);
    final trackWidth = widget.compact ? 44.0 : KkfcSizing.switchTrack;
    final trackHeight = widget.compact ? 36.0 : KkfcSizing.thumb;
    final minHeight = widget.compact
        ? KkfcSizing.controlMd
        : KkfcSizing.controlLg;

    return Semantics(
      container: true,
      toggled: widget.value,
      enabled: _enabled,
      label: [
        widget.title,
        if (widget.subtitle != null) widget.subtitle,
      ].join(', '),
      onTap: _enabled ? _toggle : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: _enabled,
          autofocus: widget.autofocus,
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _toggle();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTap: _enabled ? _toggle : null,
            // minHeight, not a fixed height, so large text scale still fits
            child: AnimatedContainer(
              duration: KkfcMotion.fast, // verify
              constraints: BoxConstraints(minHeight: minHeight),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? KkfcSpace.s12 : KkfcSpace.s16,
                vertical: widget.compact ? KkfcSpace.s8 : KkfcSpace.s12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KkfcRadius.md),
                border: Border.all(
                  width: KkfcBorderWidth.focus,
                  color: _focused ? focusColor : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: titleStyle),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!, style: subtitleStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: KkfcSpace.s16),
                  AnimatedContainer(
                    duration: KkfcMotion.fast,
                    width: trackWidth,
                    height: trackHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KkfcSpace.s4,
                    ),
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(KkfcRadius.full),
                      border: Border.all(
                        width: KkfcBorderWidth.thin,
                        color: trackBorder,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: KkfcMotion.fast,
                      alignment: widget.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: KkfcMotion.fast,
                        width: thumbWidth,
                        height: thumbBase * 0.8,
                        decoration: BoxDecoration(
                          color: thumb,
                          borderRadius: BorderRadius.circular(KkfcRadius.full),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
