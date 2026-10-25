import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

enum KitchenTicketAge { onTime, dueSoon, late }

@immutable
class KitchenTicketItem {
  const KitchenTicketItem({
    required this.quantity,
    required this.name,
    this.modifiers = const [],
  });

  final int quantity;
  final String name;
  final List<String> modifiers; // e.g. "EXTRA rice", "NO onions"
}

@immutable
class KitchenTicketData {
  const KitchenTicketData({
    required this.ticketNumber,
    required this.elapsed,
    required this.age,
    required this.status,
    required this.channel,
    required this.reference,
    required this.brand,
    required this.brandName,
    required this.items,
  });

  final String ticketNumber; // "T-014"
  final Duration elapsed;
  final KitchenTicketAge age;
  final KkfcStatus status;
  final String channel; // "GrabFood"
  final String reference; // "#GF-1001"
  final AssignedBrand brand;
  final String brandName; // "Aurelia's Inasal"
  final List<KitchenTicketItem> items;
}