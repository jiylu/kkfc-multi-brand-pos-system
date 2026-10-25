import 'package:flutter/material.dart';

import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Labelled radio button. Pass `onChanged: null` to disable it.
class KkfcRadio<T> extends StatefulWidget {
  const KkfcRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.autofocus = false,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String label;
  final bool autofocus;

  @override
  State<KkfcRadio<T>> createState() => _KkfcRadioState<T>();
}

class _KkfcRadioState<T> extends State<KkfcRadio<T>> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;
  bool get _selected => widget.value == widget.groupValue;

  void _select() {
    // A radio never un-selects itself.
    if (!_selected) widget.onChanged?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final focusColor = context.semanticColors.borderFocus; // verify the real name

    final disabledInk = scheme.onSurface.withValues(alpha: 0.38);

    // Outer circle colors per state
    final Color fill;
    final Color border;
    if (!_enabled) {
      fill = disabledInk; // the design shows a grey disc for both states
      border = disabledInk;
    } else if (_selected) {
      fill = scheme.primary;
      border = scheme.primary;
    } else {
      fill = _pressed ? scheme.surfaceContainerHighest : Colors.transparent;
      border = (_hovered || _pressed) ? scheme.onSurface : scheme.outline;
    }

    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: _enabled ? scheme.onSurface : disabledInk,
    );

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: _selected,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _select : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: _enabled,
          autofocus: widget.autofocus,
          mouseCursor:
              _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _select();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                _enabled ? () => setState(() => _pressed = false) : null,
            onTap: _enabled ? _select : null,
            // minHeight, not a fixed height, so large text scale still fits
            child: AnimatedContainer(
              duration: KkfcMotion.fast, // verify
              constraints:
                  const BoxConstraints(minHeight: KkfcSizing.controlLg),
              padding: const EdgeInsets.symmetric(horizontal: KkfcSpace.s16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KkfcRadius.md),
                border: Border.all(
                  width: KkfcBorderWidth.focus, // verify
                  color: _focused ? focusColor : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(widget.label, style: labelStyle)),
                  const SizedBox(width: KkfcSpace.s16),
                  AnimatedContainer(
                    duration: KkfcMotion.fast,
                    width: KkfcSizing.iconSm,
                    height: KkfcSizing.iconSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                      border: Border.all(
                        width: KkfcBorderWidth.thick, // verify
                        color: border,
                      ),
                    ),
                    // White center that shows only when selected
                    child: AnimatedScale(
                      duration: KkfcMotion.fast,
                      scale: _selected ? 1 : 0,
                      child: Container(
                        width: KkfcSizing.iconSm * 0.4,
                        height: KkfcSizing.iconSm * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
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