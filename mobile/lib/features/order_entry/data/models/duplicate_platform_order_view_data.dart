class DuplicatePlatformOrderViewData {
  const DuplicatePlatformOrderViewData({
    required this.tag,
    required this.title,
    required this.compactTitle,
    required this.subtitle,
    required this.matchedEyebrow,
    required this.orderTicketLabel,
    required this.orderTicketValue,
    required this.storeLabel,
    required this.storeValue,
    required this.externalLabel,
    required this.externalValue,
    required this.contextEyebrow,
    required this.contextTitle,
    required this.contextDescription,
    required this.reviewBadgeText,
    required this.brandFooter,
    required this.noticeBody,
    required this.primaryLabel,
  });

  final String tag;
  final String title;
  final String compactTitle;
  final String subtitle;
  final String matchedEyebrow;
  final String orderTicketLabel;
  final String orderTicketValue;
  final String storeLabel;
  final String storeValue;
  final String externalLabel;
  final String externalValue;
  final String contextEyebrow;
  final String contextTitle;
  final String contextDescription;
  final String reviewBadgeText;
  final String brandFooter;
  final String noticeBody;
  final String primaryLabel;

  /// Builds duplicate platform order copy from context.
  factory DuplicatePlatformOrderViewData.fromDetails({
    required String brand,
    required String channel,
    required String ticketNumber,
    required String store,
    required String externalReference,
  }) {
    const desc =
        'Same channel + store + external reference. No second kitchen ticket was created.';

    return DuplicatePlatformOrderViewData(
      tag: 'DUPLICATE FOUND',
      title: 'Already sent as $ticketNumber',
      compactTitle: 'Already sent as $ticketNumber',
      subtitle: '$channel · Existing order located',
      matchedEyebrow: 'MATCHED REFERENCE',
      orderTicketLabel: 'Order / ticket',
      orderTicketValue: ticketNumber,
      storeLabel: 'Store',
      storeValue: store,
      externalLabel: 'External #',
      externalValue: externalReference,
      contextEyebrow: 'ORDER CONTEXT',
      contextTitle: 'DUPLICATE FOUND',
      contextDescription: desc,
      reviewBadgeText: 'DESIGN REVIEW STATE',
      brandFooter: '$brand · example only',
      noticeBody: desc,
      primaryLabel: 'Back to order',
    );
  }

  // Static placeholder matching the design frame (09 · Duplicate Platform Order).
  static const sample = DuplicatePlatformOrderViewData(
    tag: 'DUPLICATE FOUND',
    title: 'Already sent as T-025',
    compactTitle: 'Already sent as T-025',
    subtitle: 'GrabFood · Existing order located',
    matchedEyebrow: 'MATCHED REFERENCE',
    orderTicketLabel: 'Order / ticket',
    orderTicketValue: 'T-025',
    storeLabel: 'Store',
    storeValue: 'Sample store',
    externalLabel: 'External #',
    externalValue: 'GF-1001',
    contextEyebrow: 'ORDER CONTEXT',
    contextTitle: 'DUPLICATE FOUND',
    contextDescription:
        'Same channel + store + external reference. No second kitchen ticket was created.',
    reviewBadgeText: 'DESIGN REVIEW STATE',
    brandFooter: 'Aurelia\'s Inasal · example only',
    noticeBody:
        'Same channel + store + external reference. No second kitchen ticket was created.',
    primaryLabel: 'Back to order',
  );
}
