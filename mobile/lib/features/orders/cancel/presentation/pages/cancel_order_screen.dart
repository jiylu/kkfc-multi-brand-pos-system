import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';
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
/// Runs in one of two modes:
///
/// * **Demo** (default): no [orderId], every value comes from [ticket] and the
///   steps are driven by the prototype controls. No request is sent.
/// * **Live**: [orderId] is set, so submitting calls
///   `POST /brands/:brandId/orders/:orderId/cancel` through
///   [CancelOrderRepository] and the server response selects the cancelled or
///   denied step. Approval and the QA state switcher stay demo-only because the
///   API has no approval route.
class CancelOrderScreen extends ConsumerStatefulWidget {
  const CancelOrderScreen({
    super.key,
    this.ticket = sampleCancelOrder,
    this.initialStep = CancelOrderStep.review,
    this.orderId,
    this.orderCode,
    this.onKeepOrder,
    this.onReturnToOrder,
    this.onBackToMenu,
    this.onRefresh,
  });

  final CancelOrderTicket ticket;

  /// Starts the prototype on a specific design frame.
  final CancelOrderStep initialStep;

  /// Real order UUID. Enables the live cancellation request.
  final String? orderId;

  /// Optional display code for the real order, for example `GC-00001`.
  final String? orderCode;

  final VoidCallback? onKeepOrder;
  final VoidCallback? onReturnToOrder;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onRefresh;

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  late CancelOrderStep _step;
  late final TextEditingController _reason;

  bool _submitting = false;
  bool _canRetry = false;
  CancelOrderOutcome? _outcome;
  String? _denialMessage;
  int? _denialStatusCode;

  bool get _isLive => widget.orderId != null;

  String get _orderRef =>
      widget.orderCode ?? widget.orderId ?? widget.ticket.number;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    // Only the demo prefills the sample reason. A live cancellation starts
    // empty so no placeholder text can be sent to the server.
    _reason = TextEditingController(
      text: _isLive || _step == CancelOrderStep.reasonRequired
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
      subtitle: '$_orderRef · Reason and stage required',
    ),
    CancelOrderStep.reasonRequired => (
      title: 'Reason is required',
      subtitle: '$_orderRef · Cancellation is still pending',
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
      subtitle: '$_orderRef · Server-confirmed result',
    ),
    CancelOrderStep.denied => (
      title: 'Cancellation denied',
      subtitle: 'Permission, changed stage or error',
    ),
  };

  String get _contextBody => switch (_step) {
    CancelOrderStep.review =>
      _isLive
          ? 'Provide a reason (max ${widget.ticket.maxReasonLength} '
                'characters). The cancellation is sent to the server. It does '
                'not refund payment or restore stock.'
          : 'Provide a reason (max ${widget.ticket.maxReasonLength} '
                'characters). Cancelling does not automatically refund or '
                'restore stock.',
    CancelOrderStep.reasonRequired =>
      _isLive
          ? 'Enter a reason before contacting the server. The order is still '
                'active until the server confirms.'
          : 'Show this error after Cancel is pressed. Do not disable the action '
                'only because the field is empty.',
    CancelOrderStep.approvalRequired =>
      'Order Staff cannot bypass approval. Follow the Supervisor route '
          'supported by the approved API.',
    CancelOrderStep.processing =>
      'Do not repeat the cancellation while pending. No refund or stock '
          'reversal is implied.',
    CancelOrderStep.cancelled =>
      _isLive
          ? 'The server recorded the cancellation and actor. Refund and stock '
                'adjustment remain separate results.'
          : 'Refund and stock adjustment are separate results. No automatic '
                'posting is assumed.',
    CancelOrderStep.denied =>
      _denialMessage ??
          'Show the authoritative order state. Recheck uncertain results before '
              'trying again.',
  };

  String get _stateLabel {
    if (_step == CancelOrderStep.cancelled) {
      return _isLive ? 'SERVER CONFIRMED' : 'SAMPLE OUTCOME';
    }
    return _isLive ? 'LIVE ORDER' : widget.ticket.exampleOnlyNote;
  }

  String get _stateCaption => _isLive ? 'SERVER STATE' : 'DESIGN REVIEW STATE';

  bool get _showsPrototypeStates =>
      !_isLive &&
      (_step == CancelOrderStep.review ||
          _step == CancelOrderStep.reasonRequired ||
          _step == CancelOrderStep.approvalRequired);

  List<CancelAction> get _actions => switch (_step) {
    CancelOrderStep.review || CancelOrderStep.reasonRequired => [
      CancelAction(
        label: 'Keep order',
        style: CancelActionStyle.secondary,
        onPressed: _submitting ? null : _keepOrder,
      ),
      CancelAction(
        label: 'Cancel order',
        style: CancelActionStyle.destructive,
        onPressed: _submitting ? null : _submit,
      ),
    ],
    CancelOrderStep.approvalRequired => [
      CancelAction(label: 'Return to order', onPressed: _returnToOrder),
    ],
    CancelOrderStep.processing => const [CancelAction(label: 'Cancelling…')],
    CancelOrderStep.cancelled => [
      CancelAction(label: 'Back to menu', onPressed: _backToMenu),
    ],
    CancelOrderStep.denied => [
      CancelAction(
        label: !_isLive
            ? 'Refresh order status'
            : _canRetry
            ? 'Retry cancellation'
            : 'Back to orders',
        onPressed: _submitting
            ? null
            : _isLive && !_canRetry
            ? _backToOrders
            : _refresh,
      ),
    ],
  };

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _step = CancelOrderStep.reasonRequired);
      return;
    }

    if (!_isLive) {
      // Demo mode: no request is sent and the screen simply moves to pending.
      setState(() {
        _outcome = null;
        _step = CancelOrderStep.processing;
      });
      return;
    }

    if (_submitting) return;

    setState(() {
      _submitting = true;
      _step = CancelOrderStep.processing;
      _denialMessage = null;
      _denialStatusCode = null;
      _canRetry = false;
    });

    final brandId = await _resolveBrandId();
    if (!mounted) return;

    if (brandId == null) {
      setState(() {
        _submitting = false;
        _step = CancelOrderStep.denied;
        _denialMessage =
            'The signed-in user is not assigned to a brand, so the order '
            'cannot be resolved.';
      });
      return;
    }

    final result = await ref
        .read(cancelOrderRepositoryProvider)
        .cancel(
          brandId: brandId,
          orderId: widget.orderId!,
          reason: _reason.text,
        );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      switch (result) {
        case CancelOrderAccepted(:final outcome):
          _outcome = outcome;
          _step = CancelOrderStep.cancelled;
        case CancelOrderDenied(
          :final message,
          :final statusCode,
          :final retryable,
        ):
          _denialMessage = message;
          _denialStatusCode = statusCode;
          _canRetry = retryable;
          _step = CancelOrderStep.denied;
      }
    });
  }

  Future<String?> _resolveBrandId() async {
    final activeId = ref.read(activeBrandProvider).id;
    if (_uuid.hasMatch(activeId)) return activeId;
    try {
      return await ref.read(authenticatedBrandIdProvider.future);
    } on Object {
      return null;
    }
  }

  void _resolveSample(bool confirmed) {
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
    // A live order has no detail screen yet, so leaving the cancellation
    // returns to the orders area rather than the menu.
    _navigate(_isLive ? AppRoutes.orders : AppRoutes.menu);
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

  /// A rejection the server will repeat (completed order, wrong role, bad ID)
  /// cannot be fixed by retrying, so the operator leaves the screen instead.
  void _backToOrders() => _navigate(AppRoutes.orders);

  void _refresh() {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
      return;
    }
    if (_isLive) {
      // The API returns the original saved cancellation for a retry, so the
      // same request is the only way to recheck the order.
      unawaited(_submit());
      return;
    }
    setState(() => _step = CancelOrderStep.processing);
  }

  void _navigate(String location) {
    GoRouter.maybeOf(context)?.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return CancelOrderShell(
      staffName: _isLive ? null : widget.ticket.staffName,
      staffRole: _isLive ? null : widget.ticket.staffRole,
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
      stateCaption: _stateCaption,
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
      CancelOrderStep.review ||
      CancelOrderStep.reasonRequired => _requestCard(),
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
          CancelDetailRow('Order', _orderRef),
          CancelDetailRow('Reason', _reason.text.trim()),
          CancelDetailRow('Status', 'Checking…', emphasized: true),
        ],
        footer: _isLive ? null : _sampleOutcomes(context),
      ),
      CancelOrderStep.cancelled => _cancelledCard(),
      CancelOrderStep.denied => _deniedCard(),
    };
  }

  Widget _requestCard() {
    final missingReason = _step == CancelOrderStep.reasonRequired;

    return CancelDetailCard(
      label: 'Cancellation request',
      rows: missingReason
          ? [
              CancelDetailRow('Order', _orderRef),
              CancelDetailRow('Status', 'Not cancelled'),
            ]
          : _isLive
          ? [
              CancelDetailRow('Order', _orderRef),
              CancelDetailRow('Server check', 'On submit'),
            ]
          : [
              CancelDetailRow('Ticket', widget.ticket.number),
              CancelDetailRow('Current stage', widget.ticket.currentStage),
            ],
      footer: CancelReasonField(
        controller: _reason,
        maxLength: widget.ticket.maxReasonLength,
        hintText: _isLive
            ? 'Enter the reason recorded with the cancellation.'
            : missingReason
            ? 'Enter a reason (required).'
            : null,
        helperText: missingReason
            ? null
            : 'Reason is required before confirming.',
        errorText: missingReason
            ? 'Error: Cancellation reason is required.'
            : null,
      ),
    );
  }

  Widget _cancelledCard() {
    if (!_isLive) {
      return CancelDetailCard(
        label: 'Cancellation recorded',
        rows: [
          CancelDetailRow('Order', 'CANCELLED', emphasized: true),
          CancelDetailRow('Ticket', 'Cancellation confirmed'),
          CancelDetailRow('Audit', 'Actor / reason / time'),
        ],
      );
    }

    final outcome = _outcome;
    return CancelDetailCard(
      label: 'Cancellation recorded',
      rows: [
        CancelDetailRow(
          'Order',
          outcome?.status ?? 'CANCELLED',
          emphasized: true,
        ),
        CancelDetailRow('Ticket', outcome?.ticketLabel ?? 'No kitchen ticket'),
        CancelDetailRow(
          'Reason',
          outcome?.cancellationReason ?? _reason.text.trim(),
        ),
        const CancelDetailRow('Audit', 'Actor and time recorded by server'),
      ],
    );
  }

  Widget _deniedCard() {
    if (!_isLive) {
      return CancelDetailCard(
        label: 'Order remains active',
        rows: [
          CancelDetailRow('Ticket', widget.ticket.number),
          CancelDetailRow('Status', 'Recheck with server', emphasized: true),
        ],
      );
    }

    return CancelDetailCard(
      label: 'Order remains active',
      rows: [
        CancelDetailRow('Order', _orderRef),
        CancelDetailRow('Status', 'Recheck with server', emphasized: true),
        if (_denialStatusCode != null)
          CancelDetailRow('Server response', 'HTTP $_denialStatusCode'),
        CancelDetailRow(
          'Reason',
          _denialMessage ?? 'The cancellation was not confirmed.',
          danger: true,
        ),
      ],
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
              onPressed: () => _resolveSample(true),
              child: const Text('Sample: Confirmed'),
            ),
            OutlinedButton(
              onPressed: () => _resolveSample(false),
              child: const Text('Sample: Denied'),
            ),
          ],
        ),
      ],
    );
  }
}
