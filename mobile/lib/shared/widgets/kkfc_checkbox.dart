import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Labelled checkbox. Pass `onChanged: null` to disable it.
class KkfcCheckbox extends StatefulWidget {
  const KkfcCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool autofocus;

  @override
  State<KkfcCheckbox> createState() => _KkfcCheckboxState();
}

class _KkfcCheckboxState extends State<KkfcCheckbox> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final focusColor = semantic.borderFocus;

    final disabledInk = scheme.onSurface.withValues(alpha: 0.38);

    // Box colors per state
    final Color fill;
    final Color border;
    if (!_enabled) {
      fill = widget.value ? disabledInk : Colors.transparent;
      border = disabledInk;
    } else if (widget.value) {
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
      checked: widget.value,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _toggle : null,
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
                _toggle();
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
            onTap: _enabled ? _toggle : null,
            // minHeight, not a fixed height, so large text scale still fits
            child: AnimatedContainer(
              duration: KkfcMotion.fast, // verify
              constraints:
                  const BoxConstraints(minHeight: KkfcSizing.controlLg),
              padding: const EdgeInsets.symmetric(horizontal: KkfcSpace.s16),
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
                  Flexible(child: Text(widget.label, style: labelStyle)),
                  const SizedBox(width: KkfcSpace.s16),
                  AnimatedContainer(
                    duration: KkfcMotion.fast,
                    width: KkfcSizing.iconSm,
                    height: KkfcSizing.iconSm,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(KkfcRadius.sm),
                      border: Border.all(
                        width: KkfcBorderWidth.thick,
                        color: border,
                      ),
                    ),
                    child: AnimatedScale(
                      duration: KkfcMotion.fast,
                      scale: widget.value ? 1 : 0.6,
                      child: AnimatedOpacity(
                        duration: KkfcMotion.fast,
                        opacity: widget.value ? 1 : 0,
                        child: Icon(
                          Symbols.check,
                          size: KkfcSizing.iconSm * 0.75,
                          color: scheme.onPrimary,
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