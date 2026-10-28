class OrderEntryRow {
  const OrderEntryRow(this.label, this.value);
  final String label;
  final String value;
}

class OrderEntryItem {
  const OrderEntryItem({
    required this.name,
    required this.quantity,
    required this.total,
    this.modifiers = const [],
  });

  final String name;
  final int quantity;
  final String total;
  final List<String> modifiers;
}

class OrderEntryViewData {
  const OrderEntryViewData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.summaryTitle,
    required this.rows,
    required this.totalLabel,
    required this.total,
    required this.statusTitle,
    required this.statusBadge,
    required this.statusMessage,
    required this.secondaryLabel,
    required this.primaryLabel,
    this.items = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String summaryTitle;
  final List<OrderEntryRow> rows;
  final List<OrderEntryItem> items;
  final String totalLabel;
  final String total;
  final String statusTitle;
  final String statusBadge;
  final String statusMessage;
  final String secondaryLabel;
  final String primaryLabel;

  /// Value of the "Brand" summary row, or an empty string if absent.
  String get brandName => rows
      .firstWhere(
        (r) => r.label == 'Brand',
        orElse: () => const OrderEntryRow('Brand', ''),
      )
      .value;

  /// Value of the "Channel" summary row, or an empty string if absent.
  String get channelLine => rows
      .firstWhere(
        (r) => r.label == 'Channel',
        orElse: () => const OrderEntryRow('Channel', ''),
      )
      .value;

  /// Formats the channel display string, combining [channel] and optional
  /// [reference] as `<channel> · <reference>` when [reference] is non-blank.
  static String formatChannelLine(String channel, [String? reference]) {
    final trimmed = reference?.trim() ?? '';
    return trimmed.isEmpty ? channel : '$channel · $trimmed';
  }

  /// Formats item count as `1 item` or `<count> items`.
  static String formatItemCount(int count) =>
      count == 1 ? '1 item' : '$count items';

  /// Same data with the "Brand" summary row set to [brandName].
  OrderEntryViewData withBrand(String brandName) =>
      withOrderDetails(brandName: brandName);

  /// Returns a copy with updated order summary fields.
  OrderEntryViewData withOrderDetails({
    String? brandName,
    String? channel,
    String? reference,
    int? itemCount,
    List<OrderEntryItem>? items,
    String? total,
  }) {
    final nextChannelLine = channel != null
        ? formatChannelLine(channel, reference)
        : null;
    final nextItemsValue = itemCount != null
        ? formatItemCount(itemCount)
        : null;

    return OrderEntryViewData(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      summaryTitle: summaryTitle,
      rows: [
        for (final row in rows)
          if (row.label == 'Brand' && brandName != null)
            OrderEntryRow('Brand', brandName)
          else if (row.label == 'Channel' && nextChannelLine != null)
            OrderEntryRow('Channel', nextChannelLine)
          else if (row.label == 'Items' && nextItemsValue != null)
            OrderEntryRow('Items', nextItemsValue)
          else
            row,
      ],
      items: items ?? this.items,
      totalLabel: totalLabel,
      total: total ?? this.total,
      statusTitle: statusTitle,
      statusBadge: statusBadge,
      statusMessage: statusMessage,
      secondaryLabel: secondaryLabel,
      primaryLabel: primaryLabel,
    );
  }

  // Static placeholder. Replace copy with the exact text from Figma.
  static const checkBeforeSending = OrderEntryViewData(
    eyebrow: 'BEFORE SENDING',
    title: 'Check before sending',
    subtitle: 'Review the order, then send it to the kitchen.',
    summaryTitle: 'Order summary',
    rows: [
      OrderEntryRow('Brand', "Aurelia's Inasal"),
      OrderEntryRow('Channel', 'Dine-in · Table 1'),
      OrderEntryRow('Items', '2 items'),
    ],
    totalLabel: 'Total',
    total: '₱537.00',
    statusTitle: 'Order status',
    statusBadge: 'Not sent',
    statusMessage: 'This order has not been sent to the kitchen yet.',
    secondaryLabel: 'Edit order',
    primaryLabel: 'Confirm & send',
  );
}
