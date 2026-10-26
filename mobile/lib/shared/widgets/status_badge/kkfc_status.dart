import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge_style.dart';

enum KkfcStatus {
  // Order / ticket flow
  queued(
    'Queued',
    Symbols.schedule,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.soft,
  ),
  acknowledged(
    'Acknowledged',
    Symbols.visibility,
    KkfcBadgeFamily.info,
    KkfcBadgeVariant.soft,
  ),
  preparing('Preparing', null, KkfcBadgeFamily.info, KkfcBadgeVariant.solid),
  checking(
    'Checking',
    Symbols.checklist,
    KkfcBadgeFamily.review,
    KkfcBadgeVariant.soft,
  ),
  reworking(
    'Reworking',
    Symbols.replay,
    KkfcBadgeFamily.review,
    KkfcBadgeVariant.solid,
  ),
  ready(
    'Ready',
    Symbols.check_circle,
    KkfcBadgeFamily.success,
    KkfcBadgeVariant.solid,
  ),
  handedOver(
    'Handed over',
    Symbols.done_all,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.subtle,
  ),
  cancelled(
    'Cancelled',
    Symbols.cancel,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.soft,
  ),
  draft(
    'Draft',
    Symbols.edit_note,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.outlined,
  ),
  confirmed(
    'Confirmed',
    Symbols.schedule,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.soft,
  ),
  completed(
    'Completed',
    Symbols.done_all,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.subtle,
  ),

  // Payment
  unpaid(
    'Unpaid',
    Symbols.schedule,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.soft,
  ),
  paid(
    'Paid',
    Symbols.task_alt,
    KkfcBadgeFamily.success,
    KkfcBadgeVariant.soft,
  ),
  refunded(
    'Refunded',
    Symbols.undo,
    KkfcBadgeFamily.neutral,
    KkfcBadgeVariant.subtle,
  ),
  success(
    'Success',
    Symbols.task_alt,
    KkfcBadgeFamily.success,
    KkfcBadgeVariant.soft,
  ),
  denied(
    'Denied',
    Symbols.block,
    KkfcBadgeFamily.danger,
    KkfcBadgeVariant.soft,
  ),
  failed(
    'Failed',
    Symbols.error,
    KkfcBadgeFamily.danger,
    KkfcBadgeVariant.soft,
  );

  const KkfcStatus(this.label, this.icon, this.family, this.variant);

  final String label;
  final IconData? icon;
  final KkfcBadgeFamily family;
  final KkfcBadgeVariant variant;
}
