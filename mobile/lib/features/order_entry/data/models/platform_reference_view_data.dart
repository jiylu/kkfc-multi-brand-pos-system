class PlatformReferenceField {
  const PlatformReferenceField({
    required this.label,
    required this.hint,
    this.required = false,
    this.errorText,
  });

  final String label;
  final String hint;
  final bool required;
  final String? errorText;
}

class PlatformReferenceViewData {
  const PlatformReferenceViewData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.storeLabel,
    required this.storeHint,
    required this.externalReferenceLabel,
    required this.externalReferenceHint,
    required this.rightTitle,
    required this.rightSubtitle,
    required this.warningTitle,
    required this.warningBody,
    required this.reviewTitle,
    required this.reviewBody,
    required this.buttonLabel,
    this.fields = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String storeLabel;
  final String storeHint;
  final String externalReferenceLabel;
  final String externalReferenceHint;
  final String rightTitle;
  final String rightSubtitle;
  final String warningTitle;
  final String warningBody;
  final String reviewTitle;
  final String reviewBody;
  final String buttonLabel;
  final List<PlatformReferenceField> fields;

  static const sample = PlatformReferenceViewData(
    eyebrow: 'ACTION NEEDED',
    title: 'Complete order details',
    subtitle: 'GrabFood · Required merchant references',
    storeLabel: 'Store',
    storeHint: 'Select store',
    externalReferenceLabel: 'External order reference',
    externalReferenceHint: 'Enter order #',
    rightTitle: 'ORDER CONTEXT',
    rightSubtitle: 'Check the exact store and external reference before sending. No ticket exists yet.',
    warningTitle: 'ACTION NEEDED',
    warningBody: 'Check the exact store and external reference before sending. No ticket exists yet.',
    reviewTitle: 'DESIGN REVIEW STATE',
    reviewBody: 'Aurelia’s Inasal · example only',
    buttonLabel: 'Edit references',
    fields: [
      PlatformReferenceField(
        label: 'Store',
        hint: 'Select store',
        required: true,
      ),
      PlatformReferenceField(
        label: 'External order reference',
        hint: 'Enter order #',
        required: true,
        errorText: 'External reference required',
      ),
    ],
  );
}
