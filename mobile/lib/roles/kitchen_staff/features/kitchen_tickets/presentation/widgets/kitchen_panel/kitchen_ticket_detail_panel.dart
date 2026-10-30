import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_actions.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_confirm_checklist.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_header.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_permission_banner.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_ticket_info.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_breakpoints.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Available presentation states for the ticket detail panel.
enum KitchenTicketPanelState {
  /// Initial queued state (02 · Queued Ticket).
  queued,

  /// Acknowledged state (03 · Acknowledge Ticket).
  acknowledged,

  /// In-progress preparation state (04 · Preparation).
  preparing,

  /// Quality check / inspection state (05 · Quality Check).
  qualityCheck,

  /// Ready for dispatch / outgoing check state (09 · Ready for Dispatch).
  readyForDispatch,

  /// Photo missing / required state (18 · Photo Missing).
  photoRequired,

  /// Photo preview / attachment review state (19 · Photo Preview).
  photoPreview,

  /// Dispatcher final check / confirm handover state (10 · Dispatcher Check).
  dispatcherCheck,

  /// Handover completed / final release state (11 · Handover Completed).
  handoverComplete,
}

/// The ticket detail panel (right panel on tablet, full queue detail on phone).
///
/// Designed as a stateless component with sample data defaults and callbacks
/// for closing the panel or acknowledging the ticket.
class KitchenTicketDetailPanel extends StatelessWidget {
  const KitchenTicketDetailPanel({
    super.key,
    this.ticket = KitchenBoardSampleData.t014,
    this.panelState = KitchenTicketPanelState.queued,
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.onBeginPreparation,
    this.onSendToQC,
    this.onPassQC,
    this.onFailQC,
    this.onContinueToHandover,
    this.onAddPhoto,
    this.onRetakePhoto,
    this.onSubmitPhoto,
    this.onConfirmHandover,
    this.onNotYet,
    this.onBackToKitchenBoard,
    this.onHistoryPending,
    this.width,
    this.borderRadius,
    this.badgeText,
    this.title,
    this.subtitle,
    this.backButtonLabel,
    this.acknowledgeButtonLabel,
    this.paymentStatus = 'PAYMENT · UNPAID',
    this.confirmationTitle,
    this.confirmationItems,
    this.permissionNotice,
  });

  /// Ticket data to display (defaults to T-014 sample data).
  final KitchenBoardItem ticket;

  /// Whether the panel is in queued, acknowledged, preparing, quality check, or ready state.
  final KitchenTicketPanelState panelState;

  /// Callback when user taps close button "×" or back button.
  final VoidCallback? onClose;

  /// Optional specific callback for the back button. Defaults to [onClose].
  final VoidCallback? onBack;

  /// Callback when user taps "Acknowledge ticket".
  final VoidCallback? onAcknowledge;

  /// Callback when user taps "Begin preparation".
  final VoidCallback? onBeginPreparation;

  /// Callback when user taps "Send to QC".
  final VoidCallback? onSendToQC;

  /// Callback when user taps "Pass QC".
  final VoidCallback? onPassQC;

  /// Callback when user taps "Fail QC".
  final VoidCallback? onFailQC;

  /// Callback when user taps "Continue to handover".
  final VoidCallback? onContinueToHandover;

  /// Callback when user taps "Add photo".
  final VoidCallback? onAddPhoto;

  /// Callback when user taps "Retake photo".
  final VoidCallback? onRetakePhoto;

  /// Callback when user taps "Submit photo".
  final VoidCallback? onSubmitPhoto;

  /// Callback when user taps "Confirm handover".
  final VoidCallback? onConfirmHandover;

  /// Callback when user taps "Not yet".
  final VoidCallback? onNotYet;

  /// Callback when user taps "Back to Kitchen Board".
  final VoidCallback? onBackToKitchenBoard;

  /// Callback when user taps "History (pending)".
  final VoidCallback? onHistoryPending;

  /// Optional fixed width for the panel (e.g. 400 or 440 on tablet).
  final double? width;

  /// Optional border radius (defaults to zero for flush docked right panel).
  final BorderRadiusGeometry? borderRadius;

  final String? badgeText;
  final String? title;
  final String? subtitle;
  final String? backButtonLabel;
  final String? acknowledgeButtonLabel;
  final String paymentStatus;
  final String? confirmationTitle;
  final List<String>? confirmationItems;
  final String? permissionNotice;

  void _handleDismiss() {
    if (onClose != null) {
      onClose!();
    } else if (onBack != null) {
      onBack!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = ticket.ticket;
    final isHandoverComplete = panelState == KitchenTicketPanelState.handoverComplete;
    final isDispatcherCheck = panelState == KitchenTicketPanelState.dispatcherCheck;
    final isPhotoPreview = panelState == KitchenTicketPanelState.photoPreview;
    final isPhotoRequired = panelState == KitchenTicketPanelState.photoRequired;
    final isReady = panelState == KitchenTicketPanelState.readyForDispatch;
    final isQC = panelState == KitchenTicketPanelState.qualityCheck;
    final isPreparing = panelState == KitchenTicketPanelState.preparing;
    final isAcknowledged = panelState == KitchenTicketPanelState.acknowledged;

    final resolvedBadgeText = badgeText ??
        (isHandoverComplete
            ? 'HANDED OVER'
            : (isDispatcherCheck
                ? 'HANDOVER'
                : (isPhotoPreview
                    ? 'PHOTO EVIDENCE · PREVIEW'
                    : (isPhotoRequired
                        ? 'PHOTO MISSING · BLOCKED'
                        : (isReady
                            ? 'READY · OUTGOING CHECK'
                            : (isQC
                                ? 'QC · CHECKER AUTHORIZATION PENDING'
                                : (isPreparing
                                    ? 'COOKING · PREPARING'
                                    : (isAcknowledged ? 'ACKNOWLEDGED' : 'NEW ORDER · QUEUED'))))))));

    final resolvedBadgeColor = (isHandoverComplete || isDispatcherCheck)
        ? const Color(0xFF16A34A)
        : ((isPhotoPreview || isPhotoRequired)
            ? const Color(0xFF0284C7)
            : (isReady
                ? const Color(0xFF16A34A)
                : (isQC
                    ? const Color(0xFF7C3AED)
                    : (isPreparing
                        ? const Color(0xFFD97706)
                        : const Color(0xFF0284C7)))));

    final resolvedHeaderBg = (isHandoverComplete || isDispatcherCheck || isReady)
        ? const Color(0xFFF0FAF4)
        : ((isPhotoPreview || isPhotoRequired)
            ? Colors.white
            : (isQC
                ? const Color(0xFFF7F3FD)
                : (isPreparing
                    ? const Color(0xFFFDF6EE)
                    : Colors.white)));

    final resolvedTopAccentColor =
        (isHandoverComplete || isDispatcherCheck || isReady) ? const Color(0xFF16A34A) : null;

    final rawNumber = ticketData.ticketNumber.replaceFirst('Ticket ', '');
    final resolvedTitle = title ??
        (isHandoverComplete
            ? 'Handover complete'
            : (isDispatcherCheck
                ? 'Confirm handover'
                : (isPhotoPreview
                    ? 'Review attachment'
                    : (isPhotoRequired
                        ? 'Photo required'
                        : (isReady
                            ? 'Outgoing check'
                            : (isQC
                                ? 'Inspect $rawNumber'
                                : (isPreparing
                                    ? 'Prepare $rawNumber'
                                    : (isAcknowledged
                                        ? 'Begin preparation'
                                        : (ticketData.ticketNumber.startsWith('Ticket')
                                            ? ticketData.ticketNumber
                                            : 'Ticket ${ticketData.ticketNumber}')))))))));

    final resolvedSubtitle = subtitle ??
        (isHandoverComplete
            ? 'Illustrative successful state'
            : (isDispatcherCheck
                ? 'Record final order release'
                : (isPhotoPreview
                    ? 'Illustrative local preview · not uploaded'
                    : (isPhotoRequired
                        ? 'Handover remains unavailable'
                        : (isReady
                            ? 'Dispatcher final review'
                            : (isQC
                                ? 'Verify the prepared order'
                                : (isPreparing
                                    ? 'Cooking in progress'
                                    : (isAcknowledged
                                        ? 'Ticket claimed by kitchen staff'
                                        : 'Ready to acknowledge'))))))));

    final resolvedConfirmTitle = confirmationTitle ??
        (isHandoverComplete
            ? 'FINAL STATE'
            : (isDispatcherCheck
                ? 'PRE-HANDOVER CHECK'
                : (isPhotoPreview
                    ? 'ATTACHMENT PREVIEW · SAMPLE'
                    : (isPhotoRequired
                        ? 'REQUIRED EVIDENCE MISSING'
                        : (isReady
                            ? 'DISPATCHER CHECK'
                            : (isQC
                                ? 'QUALITY CHECKLIST'
                                : (isPreparing
                                    ? 'PREPARATION CHECK'
                                    : (isAcknowledged ? 'START COOKING' : 'CONFIRM THE ORDER'))))))));

    final resolvedConfirmColor = (isHandoverComplete ||
            isDispatcherCheck ||
            isPhotoPreview ||
            isPhotoRequired ||
            isReady)
        ? const Color(0xFF16A34A)
        : (isQC
            ? const Color(0xFF7C3AED)
            : (isPreparing
                ? const Color(0xFFD97706)
                : const Color(0xFF0284C7)));

    final resolvedConfirmItems = confirmationItems ??
        (isHandoverComplete
            ? const [
                'Ticket handed over in prototype',
                'Payment remains independent',
              ]
            : (isDispatcherCheck
                ? const [
                    'Correct order and recipient',
                    'Check approved photo requirement',
                  ]
                : (isPhotoPreview
                    ? const [
                        'Photo selected for this ticket (demo)',
                        'Confirm the correct order and contents',
                      ]
                    : (isPhotoRequired
                        ? const [
                            'Add an authorized pre-handover photo',
                            'Ticket stays READY until verified',
                          ]
                        : (isReady
                            ? const [
                                'Confirm packing and destination',
                                'Review photo evidence rule',
                              ]
                            : (isQC
                                ? const [
                                    'Quantities and modifiers match',
                                    'Packaging and destination correct',
                                  ]
                                : (isPreparing
                                    ? const [
                                        '2 × Paa Inasal · extra rice',
                                        '1 × Pecho Inasal · no onions',
                                      ]
                                    : (isAcknowledged
                                        ? const [
                                            'Review quantities and modifiers',
                                            'Begin preparation when ready',
                                          ]
                                        : const [
                                            'Check all items and modifiers',
                                            'Verify brand and destination',
                                          ]))))))));

    final resolvedPermissionNotice = permissionNotice ??
        (isHandoverComplete
            ? 'Backend confirmation still required.'
            : (isDispatcherCheck
                ? 'Dispatcher authorization and photo policy pending.'
                : (isPhotoPreview
                    ? 'Preview alone does not persist evidence.'
                    : (isPhotoRequired
                        ? 'No completion is implied by missing evidence.'
                        : (isReady
                            ? 'Dispatcher authorization and photo policy pending.'
                            : (isQC
                                ? 'QC action shown as demo; approved checker rights required.'
                                : (isPreparing
                                    ? 'Next approved transition is CHECKING.'
                                    : (isAcknowledged
                                        ? 'Server must confirm the next status.'
                                        : 'Preparer permission requires Backend approval.'))))))));

    final defaultBack = isHandoverComplete
        ? 'History (pending)'
        : (isDispatcherCheck
            ? 'Not yet'
            : (isPhotoPreview
                ? 'Retake photo'
                : ((isPhotoRequired || isReady)
                    ? 'Keep READY'
                    : (isQC
                        ? 'Pass QC'
                        : (isPreparing
                            ? 'Keep preparing'
                            : (isAcknowledged
                                ? (context.isKitchenTablet ? 'Stay acknowledged' : 'Stay here')
                                : 'Back to board'))))));
    final resolvedBackLabel = backButtonLabel ?? defaultBack;

    final resolvedActionLabel = acknowledgeButtonLabel ??
        (isHandoverComplete
            ? 'Back to Kitchen Board'
            : (isDispatcherCheck
                ? 'Confirm handover'
                : (isPhotoPreview
                    ? 'Submit photo (demo)'
                    : (isPhotoRequired
                        ? 'Add photo'
                        : (isReady
                            ? 'Continue to handover'
                            : (isQC
                                ? 'Fail QC'
                                : (isPreparing
                                    ? 'Send to QC'
                                    : (isAcknowledged ? 'Begin preparation' : 'Acknowledge ticket'))))))));

    final resolvedOnAction = isHandoverComplete
        ? (onBackToKitchenBoard ?? onClose ?? _handleDismiss)
        : (isDispatcherCheck
            ? (onConfirmHandover ?? onAcknowledge)
            : (isPhotoPreview
                ? (onSubmitPhoto ?? onAcknowledge)
                : (isPhotoRequired
                    ? (onAddPhoto ?? onAcknowledge)
                    : (isReady
                        ? onContinueToHandover
                        : (isQC
                            ? onFailQC
                            : (isPreparing
                                ? onSendToQC
                                : (isAcknowledged
                                    ? (onBeginPreparation ?? onAcknowledge)
                                    : onAcknowledge)))))));

    final panelWidget = Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: borderRadius ?? BorderRadius.zero,
        border: const Border(
          left: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          KitchenPanelHeader(
            badgeText: resolvedBadgeText,
            badgeColor: resolvedBadgeColor,
            backgroundColor: resolvedHeaderBg,
            topAccentColor: resolvedTopAccentColor,
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            onClose: _handleDismiss,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitchenPanelTicketInfo(
                    ticket: ticketData,
                    statusOverride: isHandoverComplete
                        ? KkfcStatus.handedOver
                        : ((isDispatcherCheck ||
                                isPhotoPreview ||
                                isPhotoRequired ||
                                isReady)
                            ? KkfcStatus.ready
                            : (isQC
                                ? KkfcStatus.checking
                                : (isPreparing
                                    ? KkfcStatus.preparing
                                    : (isAcknowledged ? KkfcStatus.acknowledged : null)))),
                    paymentStatus: paymentStatus,
                  ),
                  const SizedBox(height: 12),
                  KitchenPanelConfirmChecklist(
                    title: resolvedConfirmTitle,
                    titleColor: resolvedConfirmColor,
                    items: resolvedConfirmItems,
                    showCheckIcon: !(isPhotoPreview || isPhotoRequired),
                  ),
                  const SizedBox(height: 12),
                  KitchenPanelPermissionBanner(
                    message: resolvedPermissionNotice,
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          // Action Buttons
          KitchenPanelActions(
            backLabel: resolvedBackLabel,
            acknowledgeLabel: resolvedActionLabel,
            isQC: isQC,
            onClose: _handleDismiss,
            onBack: isHandoverComplete
                ? (onHistoryPending ?? onBack ?? () {})
                : (isDispatcherCheck
                    ? (onNotYet ?? onBack ?? _handleDismiss)
                    : (isPhotoPreview
                        ? (onRetakePhoto ?? onBack ?? _handleDismiss)
                        : _handleDismiss)),
            onAcknowledge: resolvedOnAction,
            onPassQC: onPassQC ?? _handleDismiss,
            onFailQC: onFailQC,
            isAcknowledgeEnabled: isHandoverComplete ? true : ticket.isActionEnabled,
          ),
        ],
      ),
    );

    return panelWidget;
  }
}

/// Alias for [KitchenTicketDetailPanel].
typedef KitchenTicketPanel = KitchenTicketDetailPanel;
