import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Primary kitchen action for each status. Null means no action button.
String? kitchenTicketActionLabel(KkfcStatus status) => switch (status) {
  KkfcStatus.queued => 'Take ticket',
  KkfcStatus.acknowledged => 'Start',
  KkfcStatus.preparing => 'Send to QC',
  KkfcStatus.checking => 'Pass',
  KkfcStatus.reworking => 'Back to QC',
  KkfcStatus.ready => 'Hand over',
  _ => null,
};