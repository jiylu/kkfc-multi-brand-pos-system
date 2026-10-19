import 'package:flutter/material.dart';

class SessionExpiredMotion {
  SessionExpiredMotion(AnimationController controller)
      : cardIn = CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
        accentGrow = CurvedAnimation(
          parent: controller,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
        ),
        pillPop = CurvedAnimation(
          parent: controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
        );

  final Animation<double> cardIn;
  final Animation<double> accentGrow;
  final Animation<double> pillPop;
}