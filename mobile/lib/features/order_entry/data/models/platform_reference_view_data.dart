import 'package:mobile/shared/store_reference.dart';

class PlatformReferenceField {
  const PlatformReferenceField({
    required this.label,
    this.hint = '',
    this.value,
    this.readOnly = false,
    this.required = false,
    this.errorText,
  });

  final String label;
  final String hint;
  final String? value;
  final bool readOnly;
  final bool required;
  final String? errorText;
}

class PlatformReferenceViewData {
  const PlatformReferenceViewData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
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

  PlatformReferenceViewData withContext({
    required String brandName,
    required String channelLabel,
    String? externalReferenceErrorText,
  }) {
    return PlatformReferenceViewData(
      eyebrow: eyebrow,
      title: title,
      subtitle: '$channelLabel · Required merchant references',
      externalReferenceLabel: externalReferenceLabel,
      externalReferenceHint: externalReferenceHint,
      rightTitle: rightTitle,
      rightSubtitle: rightSubtitle,
      warningTitle: warningTitle,
      warningBody: warningBody,
      reviewTitle: reviewTitle,
      reviewBody: brandName,
      buttonLabel: buttonLabel,
      fields: [
        PlatformReferenceField(
          label: 'Store reference',
          value: formatStoreReference(
            brandName: brandName,
            channelLabel: channelLabel,
          ),
          readOnly: true,
        ),
        PlatformReferenceField(
          label: externalReferenceLabel,
          hint: externalReferenceHint,
          required: true,
          errorText: externalReferenceErrorText,
        ),
      ],
    );
  }

  static const sample = PlatformReferenceViewData(
    eyebrow: 'ACTION NEEDED',
    title: 'Complete order details',
    subtitle: 'GrabFood · Required merchant references',
    externalReferenceLabel: 'External order reference',
    externalReferenceHint: 'Enter order #',
    rightTitle: 'ORDER CONTEXT',
    rightSubtitle: 'Store reference follows the active brand and channel. Check the external reference before sending.',
    warningTitle: 'ACTION NEEDED',
    warningBody: 'Store reference follows the active brand and channel. Check the external reference before sending.',
    reviewTitle: 'DESIGN REVIEW STATE',
    reviewBody: 'King Kungs Kafe · example only',
    buttonLabel: 'Edit references',
    fields: [
      PlatformReferenceField(
        label: 'Store reference',
        value: 'King Kungs Kafe, GrabFood',
        readOnly: true,
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
