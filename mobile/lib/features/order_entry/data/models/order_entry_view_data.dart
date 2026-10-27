class OrderEntryRow {
  const OrderEntryRow(this.label, this.value);
  final String label;
  final String value;
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
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String summaryTitle;
  final List<OrderEntryRow> rows;
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

  /// Same data with the "Brand" summary row set to [brandName].
  OrderEntryViewData withBrand(String brandName) => OrderEntryViewData(
    eyebrow: eyebrow,
    title: title,
    subtitle: subtitle,
    summaryTitle: summaryTitle,
    rows: [
      for (final row in rows)
        row.label == 'Brand' ? OrderEntryRow('Brand', brandName) : row,
    ],
    totalLabel: totalLabel,
    total: total,
    statusTitle: statusTitle,
    statusBadge: statusBadge,
    statusMessage: statusMessage,
    secondaryLabel: secondaryLabel,
    primaryLabel: primaryLabel,
  );

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
    primaryLabel: 'Send to kitchen',
  );
}