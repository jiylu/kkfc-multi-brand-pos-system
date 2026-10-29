import 'package:flutter/material.dart';

abstract final class OrderEntryShadows {
  /// Resting cards.
  static List<BoxShadow> card(BuildContext context) {
    final c = Theme.of(context).colorScheme.shadow;
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.05),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: c.withValues(alpha: 0.08),
        blurRadius: 24,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Sticky action bar: shadow falls upward onto the content.
  static List<BoxShadow> bar(BuildContext context) {
    final c = Theme.of(context).colorScheme.shadow;
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.04),
        blurRadius: 2,
        offset: const Offset(0, -1),
      ),
      BoxShadow(
        color: c.withValues(alpha: 0.08),
        blurRadius: 16,
        spreadRadius: -4,
        offset: const Offset(0, -6),
      ),
    ];
  }

  /// Hero card (kitchen ticket on tablet).
  static List<BoxShadow> raised(BuildContext context) {
    final c = Theme.of(context).colorScheme.shadow;
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.06),
        blurRadius: 3,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: c.withValues(alpha: 0.12),
        blurRadius: 32,
        spreadRadius: -8,
        offset: const Offset(0, 16),
      ),
    ];
  }
}
