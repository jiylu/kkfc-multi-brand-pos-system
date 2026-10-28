import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/features/orders/cancel/data/seed/sample_cancel_order.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_action_bar.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_context_card.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_detail_card.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_order_shell.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_prototype_states.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_reason_field.dart';
import 'package:mobile/features/orders/cancel/presentation/widgets/cancel_state_header.dart';
import 'package:mobile/shared/shared_layout.dart';

/// Cancel-order workflow UI (design frames 10-15).
///
/// The backend has no cancellation endpoint yet: the steps are driven by the
/// prototype controls in this screen, and every ticket value comes from
/// [sampleCancelOrder]. Nothing is sent to the API.
class CancelOrderScreen extends StatefulWidget {
  const CancelOrderScreen({
    super.key,
    this.ticket = sampleCancelOrder,
    this.initialStep = CancelOrderStep.review,
    this.onKeepOrder,
    this.onReturnToOrder,
    this.onBackToMenu,
    this.onRefresh,
  });

  final CancelOrderTicket ticket;

  /// Starts the prototype on a specific design frame.
  final CancelOrderStep initialStep;

  final VoidCallback? onKeepOrder;
  final VoidCallback? onReturnToOrder;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onRefresh;

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  late CancelOrderStep _step;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _reason = TextEditingController(
      text: _step == CancelOrderStep.reasonRequired
          ? ''
          : sampleCancellationReason,
    );
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  ({String title, String subtitle}) get _copy => switch (_step) {
    CancelOrderStep.review => (
      title: 'Cancel this order?',
      subtitle: '${widget.ticket.number} · Reason and stage required',
    ),
    CancelOrderStep.reasonRequired => (
      title: 'Reason is required',
      subtitle: '${widget.ticket.number} · Cancellation is still pending',
    ),
    CancelOrderStep.approvalRequired => (
      title: 'Approval needed',
      subtitle: 'Preparation has already started',
    ),
    CancelOrderStep.processing => (
      title: 'Cancelling order',
      subtitle: 'Awaiting authoritative server response',
    ),
    CancelOrderStep.cancelled => (
      title: 'Order cancelled',
      subtitle: '${widget.ticket.number} · Server-confirmed result',
    ),
    CancelOrderStep.denied => (
      title: 'Cancellation denied',
      subtitle: 'Permission, changed stage or error',
    ),
  };

  String get _contextBody => switch (_step) {
    CancelOrderStep.review =>
      'Provide a reason (max ${widget.ticket.maxReasonLength} characters). '
          'Cancelling does not automatically refund or restore stock.',
    CancelOrderStep.reasonRequired =>
      'Show this error after Cancel is pressed. Do not disable the action '
          'only because the field is empty.',
    CancelOrderStep.approvalRequired =>
      'Order Staff cannot bypass approval. Follow the Supervisor route '
          'supported by the approved API.',
    CancelOrderStep.processing =>
      'Do not repeat the cancellation while pending. No refund or stock '
          'reversal is implied.',
    CancelOrderStep.cancelled =>
      'Refund and stock adjustment are separate results. No automatic '
          'posting is assumed.',
    CancelOrderStep.denied =>
      'Show the authoritative order state. Recheck uncertain results before '
          'trying again.',
  };

  String get _stateLabel => _step == CancelOrderStep.cancelled
      ? 'SERVER CONFIRMED'
      : widget.ticket.exampleOnlyNote;

  bool get _showsPrototypeStates =>
      _step == CancelOrderStep.review ||
      _step == CancelOrderStep.reasonRequired ||
      _step == CancelOrderStep.approvalRequired;

  List<CancelAction> get _actions => switch (_step) {
    CancelOrderStep.review || CancelOrderStep.reasonRequired => [
      CancelAction(
        label: 'Keep order',
        style: CancelActionStyle.secondary,
        onPressed: _keepOrder,
      ),
      CancelAction(
        label: 'Cancel order',
        style: CancelActionStyle.destructive,
        onPressed: _submit,
      ),
    ],
    CancelOrderStep.approvalRequired => [
      CancelAction(label: 'Return to order', onPressed: _returnToOrder),
    ],
    CancelOrderStep.processing => const [
      CancelAction(label: 'Processing…'),
    ],
    CancelOrderStep.cancelled => [
      CancelAction(label: 'Back to menu', onPressed: _backToMenu),
    ],
    CancelOrderStep.denied => [
      CancelAction(label: 'Refresh order status', onPressed: _refresh),
    ],
  };

  void _submit() {
    if (_reason.text.trim().isEmpty) {
      setState(() => _step = CancelOrderStep.reasonRequired);
      return;
    }

    // TODO: POST the cancellation once the endpoint exists. Until then no
    // request is sent and the screen simply moves to the pending state.
    setState(() => _step = CancelOrderStep.processing);
  }

  void _resolve(bool confirmed) {
    setState(
      () => _step = confirmed
          ? CancelOrderStep.cancelled
          : CancelOrderStep.denied,
    );
  }

  void _selectStep(CancelOrderStep step) {
    setState(() {
      _step = step;
      if (step == CancelOrderStep.reasonRequired) {
        _reason.clear();
      } else if (_reason.text.isEmpty) {
        _reason.text = sampleCancellationReason;
      }
    });
  }

  void _keepOrder() {
    if (widget.onKeepOrder != null) {
      widget.onKeepOrder!();
      return;
    }
    _navigate(AppRoutes.menu);
  }

  void _returnToOrder() {
    if (widget.onReturnToOrder != null) {
      widget.onReturnToOrder!();
      return;
    }
    _navigate(AppRoutes.menu);
  }

  void _backToMenu() {
    if (widget.onBackToMenu != null) {
      widget.onBackToMenu!();
      return;
    }
    _navigate(AppRoutes.menu);
  }

  void _refresh() {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
      return;
    }
    // TODO: re-read the order once GET /orders/:id exists.
    setState(() => _step = CancelOrderStep.processing);
  }

  void _navigate(String location) {
    GoRouter.maybeOf(context)?.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return CancelOrderShell(
      staffName: widget.ticket.staffName,
      staffRole: widget.ticket.staffRole,
      header: CancelStateHeader(
        step: _step,
        title: _copy.title,
        subtitle: _copy.subtitle,
      ),
      actions: _actions,
      bodyBuilder: _body,
    );
  }

  Widget _body(BuildContext context, bool isTablet) {
    final primaryCard = _primaryCard(context);
    final contextCard = CancelContextCard(
      step: _step,
      body: _contextBody,
      stateLabel: _stateLabel,
      compact: !isTablet,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: primaryCard),
              SizedBox(width: MenuSpace.xl),
              Expanded(flex: 2, child: contextCard),
            ],
          )
        else ...[
          primaryCard,
          SizedBox(height: MenuSpace.lg),
          contextCard,
        ],
        if (_showsPrototypeStates) ...[
          SizedBox(height: MenuSpace.xl),
          CancelPrototypeStates(current: _step, onSelected: _selectStep),
        ],
      ],
    );
  }

  Widget _primaryCard(BuildContext context) {
    return switch (_step) {
      CancelOrderStep.review || CancelOrderStep.reasonRequired => _requestCard(),
      CancelOrderStep.approvalRequired => CancelDetailCard(
        label: 'Restricted action',
        rows: [
          CancelDetailRow('Ticket', widget.ticket.number),
          CancelDetailRow(
            'Kitchen stage',
            widget.ticket.kitchenStage,
            emphasized: true,
          ),
          CancelDetailRow('Your access', 'Not authorized', danger: true),
        ],
      ),
      CancelOrderStep.processing => CancelDetailCard(
        label: 'Request in progress',
        rows: [
          CancelDetailRow('Ticket', widget.ticket.number),
          CancelDetailRow('Reason', 'Customer request'),
          CancelDetailRow('Status', 'Checking…', emphasized: true),
        ],
        footer: _sampleOutcomes(context),
      ),
      CancelOrderStep.cancelled => CancelDetailCard(
        label: 'Cancellation recorded',
        rows: [
          CancelDetailRow('Order', 'CANCELLED', emphasized: true),
          CancelDetailRow('Ticket', 'Cancellation confirmed'),
          CancelDetailRow('Audit', 'Actor / reason / time'),
        ],
      ),
      CancelOrderStep.denied => CancelDetailCard(
        label: 'Order remains active',
        rows: [
          CancelDetailRow('Ticket', widget.ticket.number),
          CancelDetailRow('Status', 'Recheck with server', emphasized: true),
        ],
      ),
    };
  }

  Widget _requestCard() {
    final missingReason = _step == CancelOrderStep.reasonRequired;

    return CancelDetailCard(
      label: 'Cancellation request',
      rows: missingReason
          ? [
              CancelDetailRow('Ticket', widget.ticket.number),
              CancelDetailRow('Status', 'Not cancelled'),
            ]
          : [
              CancelDetailRow('Ticket', widget.ticket.number),
              CancelDetailRow('Current stage', widget.ticket.currentStage),
            ],
      footer: CancelReasonField(
        controller: _reason,
        maxLength: widget.ticket.maxReasonLength,
        hintText: missingReason ? 'Enter a reason (required).' : null,
        helperText: missingReason
            ? null
            : 'Reason is required before confirming.',
        errorText: missingReason
            ? 'Error: Cancellation reason is required.'
            : null,
      ),
    );
  }

  Widget _sampleOutcomes(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIGMA QA ONLY · SAMPLE OUTCOMES',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: MenuSpace.sm),
        Wrap(
          spacing: MenuSpace.sm,
          runSpacing: MenuSpace.sm,
          children: [
            OutlinedButton(
              onPressed: () => _resolve(true),
              child: const Text('Sample: Confirmed'),
            ),
            OutlinedButton(
              onPressed: () => _resolve(false),
              child: const Text('Sample: Denied'),
            ),
          ],
        ),
      ],
    );
  }
}
