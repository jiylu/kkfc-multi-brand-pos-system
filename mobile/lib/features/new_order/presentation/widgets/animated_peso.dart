import 'package:flutter/material.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/shared_layout.dart';

class AnimatedPeso extends StatelessWidget {
  const AnimatedPeso({super.key, required this.centavos, this.style});

  final int centavos;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: centavos),
      duration: context.motion(MenuMotion.slow),
      curve: MenuMotion.curve,
      builder: (context, value, _) => Text(formatPeso(value), style: style),
    );
  }
}
