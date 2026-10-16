import 'package:flutter/material.dart';

import 'package:mobile/core/models/order_status.dart';
import 'semantic_colors.dart';

@immutable
class KkfcStatusColors extends ThemeExtension<KkfcStatusColors> {
  const KkfcStatusColors({
    required this.draft,
    required this.queued,
    required this.acknowledged,
    required this.preparing,
    required this.checking,
    required this.reworking,
    required this.ready,
    required this.handedOver,
    required this.cancelled,
  });

  final KkfcTone draft;
  final KkfcTone queued;
  final KkfcTone acknowledged;
  final KkfcTone preparing;
  final KkfcTone checking;
  final KkfcTone reworking;
  final KkfcTone ready;
  final KkfcTone handedOver;
  final KkfcTone cancelled;

  /// Exhaustive: adding an OrderStatus without a field here is a compile error.
  KkfcTone toneFor(OrderStatus status) => switch (status) {
        OrderStatus.draft => draft,
        OrderStatus.queued => queued,
        OrderStatus.acknowledged => acknowledged,
        OrderStatus.preparing => preparing,
        OrderStatus.checking => checking,
        OrderStatus.reworking => reworking,
        OrderStatus.ready => ready,
        OrderStatus.handedOver => handedOver,
        OrderStatus.cancelled => cancelled,
      };

  // Light (counter), from theme/light status
  static const light = KkfcStatusColors(
    // TEMPORARY: the design system has no draft status. Confirm with designers.
    draft: KkfcTone(bg: Color(0xFFE3E7EF), fg: Color(0xFF283650), border: Color(0xFF9CA9C0)),
    queued: KkfcTone(bg: Color(0xFFE3E7EF), fg: Color(0xFF283650), border: Color(0xFF9CA9C0)), // ink.100 / ink.700 / ink.300
    acknowledged: KkfcTone(bg: Color(0xFFE1EAFB), fg: Color(0xFF173F8A), border: Color(0xFF93B4EE)), // blue.100 / blue.800 / blue.300
    preparing: KkfcTone(bg: Color(0xFF1F5FD6), fg: Color(0xFFFFFFFF), border: Color(0xFF1F5FD6)), // blue.600 / white
    checking: KkfcTone(bg: Color(0xFFF7E3F3), fg: Color(0xFF6E1D60), border: Color(0xFFE2A0D6)), // magenta.100 / magenta.800 / magenta.300
    reworking: KkfcTone(bg: Color(0xFFB0309A), fg: Color(0xFFFFFFFF), border: Color(0xFFB0309A)), // magenta.600 / white
    ready: KkfcTone(bg: Color(0xFF0E7A68), fg: Color(0xFFFFFFFF), border: Color(0xFF0E7A68)), // teal.700 / white
    handedOver: KkfcTone(bg: Color(0xFFF2F4F8), fg: Color(0xFF374763), border: Color(0xFFC7CFDD)), // ink.50 / ink.600 / ink.200
    cancelled: KkfcTone(bg: Color(0xFFF2F4F8), fg: Color(0xFF4C5D7D), border: Color(0xFF9CA9C0)), // ink.50 / ink.500 / ink.300
  );

  // Dark (kitchen), from theme/dark status
  static const dark = KkfcStatusColors(
    // TEMPORARY: the design system has no draft status. Confirm with designers.
    draft: KkfcTone(bg: Color(0xFF1D2940), fg: Color(0xFFC7CFDD), border: Color(0xFF374763)),
    queued: KkfcTone(bg: Color(0xFF1D2940), fg: Color(0xFFC7CFDD), border: Color(0xFF374763)), // ink.800 / ink.200 / ink.600
    acknowledged: KkfcTone(bg: Color(0xFF0C1D3F), fg: Color(0xFF93B4EE), border: Color(0xFF173F8A)), // blue.950 / blue.300 / blue.800
    preparing: KkfcTone(bg: Color(0xFF1F5FD6), fg: Color(0xFFFFFFFF), border: Color(0xFF1F5FD6)), // blue.600 / white
    checking: KkfcTone(bg: Color(0xFF330D2C), fg: Color(0xFFE2A0D6), border: Color(0xFF6E1D60)), // magenta.950 / magenta.300 / magenta.800
    reworking: KkfcTone(bg: Color(0xFFB0309A), fg: Color(0xFFFFFFFF), border: Color(0xFFB0309A)), // magenta.600 / white
    ready: KkfcTone(bg: Color(0xFF0E7A68), fg: Color(0xFFFFFFFF), border: Color(0xFF0E7A68)), // teal.700 / white
    handedOver: KkfcTone(bg: Color(0xFF141D2E), fg: Color(0xFF9CA9C0), border: Color(0xFF283650)), // ink.900 / ink.300 / ink.700
    cancelled: KkfcTone(bg: Color(0xFF141D2E), fg: Color(0xFF9CA9C0), border: Color(0xFF283650)), // ink.900 / ink.300 / ink.700
  );

  @override
  KkfcStatusColors copyWith({
    KkfcTone? draft,
    KkfcTone? queued,
    KkfcTone? acknowledged,
    KkfcTone? preparing,
    KkfcTone? checking,
    KkfcTone? reworking,
    KkfcTone? ready,
    KkfcTone? handedOver,
    KkfcTone? cancelled,
  }) {
    return KkfcStatusColors(
      draft: draft ?? this.draft,
      queued: queued ?? this.queued,
      acknowledged: acknowledged ?? this.acknowledged,
      preparing: preparing ?? this.preparing,
      checking: checking ?? this.checking,
      reworking: reworking ?? this.reworking,
      ready: ready ?? this.ready,
      handedOver: handedOver ?? this.handedOver,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  KkfcStatusColors lerp(ThemeExtension<KkfcStatusColors>? other, double t) {
    if (other is! KkfcStatusColors) return this;
    return KkfcStatusColors(
      draft: KkfcTone.lerp(draft, other.draft, t),
      queued: KkfcTone.lerp(queued, other.queued, t),
      acknowledged: KkfcTone.lerp(acknowledged, other.acknowledged, t),
      preparing: KkfcTone.lerp(preparing, other.preparing, t),
      checking: KkfcTone.lerp(checking, other.checking, t),
      reworking: KkfcTone.lerp(reworking, other.reworking, t),
      ready: KkfcTone.lerp(ready, other.ready, t),
      handedOver: KkfcTone.lerp(handedOver, other.handedOver, t),
      cancelled: KkfcTone.lerp(cancelled, other.cancelled, t),
    );
  }
}