class OrderNotSentViewData {
  const OrderNotSentViewData({
    required this.tag,
    required this.title,
    required this.compactTitle,
    required this.subtitle,
    required this.draftEyebrow,
    required this.statusLabel,
    required this.statusValue,
    required this.cartLabel,
    required this.cartValue,
    required this.totalLabel,
    required this.totalValue,
    required this.contextEyebrow,
    required this.contextTitle,
    required this.contextDescription,
    required this.reviewBadgeText,
    required this.brandFooter,
    required this.noticeBody,
    required this.secondaryLabel,
    required this.primaryLabel,
  });

  final String tag;
  final String title;
  final String compactTitle;
  final String subtitle;
  final String draftEyebrow;
  final String statusLabel;
  final String statusValue;
  final String cartLabel;
  final String cartValue;
  final String totalLabel;
  final String totalValue;
  final String contextEyebrow;
  final String contextTitle;
  final String contextDescription;
  final String reviewBadgeText;
  final String brandFooter;
  final String noticeBody;
  final String secondaryLabel;
  final String primaryLabel;

  /// Builds rejection copy from order / cart details.
  factory OrderNotSentViewData.fromCart({
    required String brand,
    required int itemCount,
    required String formattedTotal,
    String? status,
    String? errorMessage,
  }) {
    final itemText = itemCount == 1 ? '1 item preserved' : '$itemCount items preserved';
    final desc = errorMessage ??
        'Fix the reported error. Retry only through the agreed safe submission path.';

    return OrderNotSentViewData(
      tag: 'NOT SENT',
      title: 'Order not sent',
      compactTitle: 'Order not sent',
      subtitle: 'A definite server rejection was received',
      draftEyebrow: 'YOUR DRAFT IS SAFE',
      statusLabel: 'Status',
      statusValue: status ?? 'Not created',
      cartLabel: 'Cart',
      cartValue: itemText,
      totalLabel: 'Total',
      totalValue: formattedTotal,
      contextEyebrow: 'ORDER CONTEXT',
      contextTitle: 'NOT SENT',
      contextDescription: desc,
      reviewBadgeText: 'DESIGN REVIEW STATE',
      brandFooter: '$brand · example only',
      noticeBody: desc,
      secondaryLabel: 'Edit order',
      primaryLabel: 'Retry safely',
    );
  }

  // Static placeholder used only for previews and tests matching the design mockup.
  static const sample = OrderNotSentViewData(
    tag: 'NOT SENT',
    title: 'Order not sent',
    compactTitle: 'Order not sent',
    subtitle: 'A definite server rejection was received',
    draftEyebrow: 'YOUR DRAFT IS SAFE',
    statusLabel: 'Status',
    statusValue: 'Not created',
    cartLabel: 'Cart',
    cartValue: '3 items preserved',
    totalLabel: 'Total',
    totalValue: '₱597.00',
    contextEyebrow: 'ORDER CONTEXT',
    contextTitle: 'NOT SENT',
    contextDescription:
        'Fix the reported error. Retry only through the agreed safe submission path.',
    reviewBadgeText: 'DESIGN REVIEW STATE',
    brandFooter: 'Aurelia\'s Inasal · example only',
    noticeBody:
        'Fix the reported error. Retry only through the agreed safe submission path.',
    secondaryLabel: 'Edit order',
    primaryLabel: 'Retry safely',
  );
}
