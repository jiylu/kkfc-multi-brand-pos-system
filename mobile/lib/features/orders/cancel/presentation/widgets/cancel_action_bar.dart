import 'package:flutter/material.dart';

import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/shared_layout.dart';

enum CancelActionStyle { secondary, destructive, primary }

@immutable
class CancelAction {
  const CancelAction({
    required this.label,
    this.style = CancelActionStyle.primary,
    this.onPressed,
  });

  final String label;
  final CancelActionStyle style;

  /// Null disables the action (e.g. "Processing…" while pending).
  final VoidCallback? onPressed;
}

/// Footer actions for the cancel-order screens.
///
/// Tablet keeps the fixed-width pairing from the designs; phone stretches the
/// actions across the pinned footer.
class CancelActionBar extends StatelessWidget {
  const CancelActionBar({
    super.key,
    required this.actions,
    required this.expanded,
  });

  final List<CancelAction> actions;

  /// True on phone, where every action fills its share of the width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: MenuSpace.md),
          expanded
              ? Expanded(child: _button(context, actions[i]))
              : SizedBox(
                  width: actions.length == 1 ? 360 : 240,
                  child: _button(context, actions[i]),
                ),
        ],
      ],
    );
  }

  Widget _button(BuildContext context, CancelAction action) {
    final scheme = Theme.of(context).colorScheme;
    final style = action.style;

    if (style == CancelActionStyle.secondary) {
      return OutlinedButton(
        onPressed: action.onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(KkfcSizing.controlMd),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KkfcRadius.md),
          ),
        ),
        child: Text(action.label),
      );
    }

    return FilledButton(
      onPressed: action.onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(KkfcSizing.controlMd),
        backgroundColor: style == CancelActionStyle.destructive
            ? scheme.error
            : null,
        foregroundColor: style == CancelActionStyle.destructive
            ? scheme.onError
            : null,
      ),
      child: Text(action.label),
    );
  }
}
