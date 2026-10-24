import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

import 'motion.dart';

class AvailabilityToggle extends StatelessWidget {
  const AvailabilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = motionOf(context, KkfcMotion.normal);
    final radius = BorderRadius.circular(KkfcRadius.md);

    return Semantics(
      button: true,
      toggled: value,
      label: semanticLabel,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
              minWidth: 96,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: KkfcSpace.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      value ? 'On' : 'Off',
                      key: ValueKey(value),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  SizedBox(width: KkfcSpace.sm),
                  _Track(value: value, duration: duration),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.value, required this.duration});

  final bool value;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: 36,
      height: 18,
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: value ? scheme.primary : scheme.outlineVariant,
        shape: const StadiumBorder(),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: duration,
          width: 12,
          height: 12,
          decoration: ShapeDecoration(
            color: value ? scheme.onPrimary : scheme.surface,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}