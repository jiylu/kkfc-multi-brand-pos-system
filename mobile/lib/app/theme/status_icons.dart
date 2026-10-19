import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mobile/core/models/order_status.dart';

IconData statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.draft => Symbols.edit_note, // TEMPORARY: not in the design system
  OrderStatus.queued => Symbols.schedule,
  OrderStatus.acknowledged => Symbols.visibility,
  OrderStatus.preparing => Symbols.skillet,
  OrderStatus.checking => Symbols.fact_check,
  OrderStatus.reworking => Symbols.replay,
  OrderStatus.ready => Symbols.check_circle,
  OrderStatus.handedOver => Symbols.done_all,
  OrderStatus.cancelled => Symbols.cancel,
};
