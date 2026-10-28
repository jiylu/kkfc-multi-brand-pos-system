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
  /// [storeReference] / [reference] when non-blank.
  static String formatChannelLine(
    String channel, [
    String? reference,
    String? storeReference,
  ]) {
    final trimmedStore = storeReference?.trim() ?? '';
    final trimmedRef = reference?.trim() ?? '';
    return [
      channel,
      if (trimmedStore.isNotEmpty) trimmedStore,
      if (trimmedRef.isNotEmpty) trimmedRef,
    ].join(' · ');
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
    String? storeReference,
    int? itemCount,
    List<OrderEntryItem>? items,
    String? total,
  }) {
    final trimmedStore = storeReference?.trim() ?? '';
    final nextChannelLine = channel != null
        ? formatChannelLine(channel, reference, storeReference)
        : null;
    final nextItemsValue = itemCount != null
        ? formatItemCount(itemCount)
        : null;

    final updatedRows = <OrderEntryRow>[];
    var hasStoreRow = false;
    for (final row in rows) {
      if (row.label == 'Brand' && brandName != null) {
        updatedRows.add(OrderEntryRow('Brand', brandName));
      } else if (row.label == 'Store') {
        hasStoreRow = true;
        if (trimmedStore.isNotEmpty) {
          updatedRows.add(OrderEntryRow('Store', trimmedStore));
        }
      } else if (row.label == 'Channel') {
        if (trimmedStore.isNotEmpty && !hasStoreRow) {
          updatedRows.add(OrderEntryRow('Store', trimmedStore));
          hasStoreRow = true;
        }
        updatedRows.add(
          nextChannelLine != null
              ? OrderEntryRow('Channel', nextChannelLine)
              : row,
        );
      } else if (row.label == 'Items' && nextItemsValue != null) {
        updatedRows.add(OrderEntryRow('Items', nextItemsValue));
      } else {
        updatedRows.add(row);
      }
    }

    return OrderEntryViewData(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      summaryTitle: summaryTitle,
      rows: updatedRows,
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
