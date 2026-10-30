import 'package:flutter/foundation.dart';

/// One screen of the cancel-order workflow (design frames 10-15).
///
/// Demo mode moves between these steps locally. Live mode (`orderId` set) lets
/// the server response select [cancelled] or [denied]; approval stays demo-only
/// because the API has no approval route.
enum CancelOrderStep {
  review('Review request'),
  reasonRequired('Missing reason'),
  approvalRequired('Supervisor approval'),
  processing('Cancellation pending'),
  cancelled('Cancellation outcome'),
  denied('Cancellation denied');

  const CancelOrderStep(this.label);

  /// Short label for the prototype state switcher. Not product copy.
  final String label;
}

/// Tone used by the banner, the status icon tile and the review-state chip.
enum CancelTone { warning, danger, info, success }

extension CancelOrderStepDesign on CancelOrderStep {
  /// Uppercase pill copy above the page title.
  String get bannerLabel => switch (this) {
    CancelOrderStep.review => 'REVIEW REQUEST',
    CancelOrderStep.reasonRequired => 'FIX THIS FIELD',
    CancelOrderStep.approvalRequired => 'SUPERVISOR REQUIRED',
    CancelOrderStep.processing => 'PROCESSING',
    CancelOrderStep.cancelled => 'CANCELLED',
    CancelOrderStep.denied => 'ACTION NOT COMPLETED',
  };

  CancelTone get tone => switch (this) {
    CancelOrderStep.review ||
    CancelOrderStep.approvalRequired => CancelTone.warning,
    CancelOrderStep.reasonRequired => CancelTone.danger,
    CancelOrderStep.processing => CancelTone.info,
    CancelOrderStep.cancelled => CancelTone.success,
    CancelOrderStep.denied => CancelTone.danger,
  };

  /// The denied screen shows a neutral info icon in a danger banner.
  CancelTone get iconTone => switch (this) {
    CancelOrderStep.denied => CancelTone.info,
    _ => tone,
  };
}

/// Sample order shown in demo mode, before an order UUID is available.
///
/// The cancellation endpoint exists (`POST /brands/:brandId/orders/:orderId/cancel`),
/// but there is no order list to pick a real order from, so the demo screens
/// still run on this fixture.
@immutable
class CancelOrderTicket {
  const CancelOrderTicket({
    required this.number,
    required this.brandName,
    required this.staffName,
    required this.staffRole,
    required this.currentStage,
    required this.kitchenStage,
    required this.maxReasonLength,
  });

  final String number;
  final String brandName;
  final String staffName;
  final String staffRole;

  /// Stage reported by the server on the review screen.
  final String currentStage;

  /// Kitchen stage that decides whether supervisor approval is needed.
  final String kitchenStage;

  final int maxReasonLength;

  /// Design-review chip copy used by the prototype screens.
  String get exampleOnlyNote => '$brandName · example only';
}
