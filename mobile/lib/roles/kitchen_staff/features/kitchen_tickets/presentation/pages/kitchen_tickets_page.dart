import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_tickets_view_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/empty_queue_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/kitchen_board_phone_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/kitchen_board_tablet_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board_heading.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_filter_bar.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_ticket_detail_panel.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/kitchen_sample_badge.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_stage_tabs.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/loading_queue_view.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_breakpoints.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_shell.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Kitchen Board (tablet) / Ticket queue (phone). Static states only.
class KitchenTicketsPage extends StatefulWidget {
  const KitchenTicketsPage({
    super.key,
    this.viewState = KitchenTicketsViewState.active,
    this.selectedTicket,
    this.initialPanelState = KitchenTicketPanelState.queued,
    this.onClosePanel,
    this.onTicketAction,
    this.onAcknowledgeTicket,
    this.onBeginPreparation,
    this.onSendToQC,
    this.onPassQC,
    this.onFailQC,
    this.onContinueToHandover,
    this.onAddPhoto,
  });

  final KitchenTicketsViewState viewState;
  final KitchenBoardItem? selectedTicket;
  final KitchenTicketPanelState initialPanelState;
  final VoidCallback? onClosePanel;
  final void Function(KitchenBoardItem item)? onTicketAction;
  final VoidCallback? onAcknowledgeTicket;
  final VoidCallback? onBeginPreparation;
  final VoidCallback? onSendToQC;
  final VoidCallback? onPassQC;
  final VoidCallback? onFailQC;
  final VoidCallback? onContinueToHandover;
  final VoidCallback? onAddPhoto;

  @override
  State<KitchenTicketsPage> createState() => _KitchenTicketsPageState();
}

class _KitchenTicketsPageState extends State<KitchenTicketsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scrimAnimation;
  late KitchenTicketPanelState _panelState;

  KitchenBoardItem? _localSelectedTicket;
  KitchenBoardItem? _displayedTicket;
  bool _manuallyDismissed = false;

  @override
  void initState() {
    super.initState();
    _displayedTicket = widget.selectedTicket;
    _panelState = widget.initialPanelState;
    if (widget.initialPanelState == KitchenTicketPanelState.photoRequired) {
      _panelState = KitchenTicketPanelState.photoRequired;
    } else if (widget.selectedTicket?.ticket.status == KkfcStatus.ready) {
      _panelState = KitchenTicketPanelState.readyForDispatch;
    } else if (widget.selectedTicket?.ticket.status == KkfcStatus.checking) {
      _panelState = KitchenTicketPanelState.qualityCheck;
    } else if (widget.selectedTicket?.ticket.status == KkfcStatus.preparing) {
      _panelState = KitchenTicketPanelState.preparing;
    } else if (widget.selectedTicket?.ticket.status == KkfcStatus.acknowledged) {
      _panelState = KitchenTicketPanelState.acknowledged;
    }

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _scrimAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    if (widget.selectedTicket != null) {
      _panelController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(KitchenTicketsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTicket != null && oldWidget.selectedTicket == null) {
      _displayedTicket = widget.selectedTicket;
      if (widget.initialPanelState == KitchenTicketPanelState.photoRequired) {
        _panelState = KitchenTicketPanelState.photoRequired;
      } else if (widget.selectedTicket?.ticket.status == KkfcStatus.ready) {
        _panelState = KitchenTicketPanelState.readyForDispatch;
      } else if (widget.selectedTicket?.ticket.status == KkfcStatus.checking) {
        _panelState = KitchenTicketPanelState.qualityCheck;
      } else if (widget.selectedTicket?.ticket.status == KkfcStatus.preparing) {
        _panelState = KitchenTicketPanelState.preparing;
      } else if (widget.selectedTicket?.ticket.status == KkfcStatus.acknowledged) {
        _panelState = KitchenTicketPanelState.acknowledged;
      } else {
        _panelState = widget.initialPanelState;
      }
      _manuallyDismissed = false;
      _openPanel();
    } else if (widget.selectedTicket == null && oldWidget.selectedTicket != null) {
      _closePanel();
    } else if (widget.selectedTicket != null &&
        widget.selectedTicket != oldWidget.selectedTicket) {
      setState(() {
        _displayedTicket = widget.selectedTicket;
      });
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  KitchenBoardItem? get _activeTicket {
    if (_manuallyDismissed) return null;
    return widget.selectedTicket ?? _localSelectedTicket ?? _displayedTicket;
  }

  void _openPanel() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _panelController.value = 1.0;
    } else {
      _panelController.forward(from: 0.0);
    }
  }

  void _handleTicketAction(KitchenBoardItem item) {
    widget.onTicketAction?.call(item);
    setState(() {
      _localSelectedTicket = item;
      _displayedTicket = item;
      if (item.ticket.status == KkfcStatus.ready) {
        _panelState = KitchenTicketPanelState.readyForDispatch;
      } else if (item.ticket.status == KkfcStatus.checking) {
        _panelState = KitchenTicketPanelState.qualityCheck;
      } else if (item.ticket.status == KkfcStatus.preparing) {
        _panelState = KitchenTicketPanelState.preparing;
      } else if (item.ticket.status == KkfcStatus.acknowledged) {
        _panelState = KitchenTicketPanelState.acknowledged;
      } else {
        _panelState = KitchenTicketPanelState.queued;
      }
      _manuallyDismissed = false;
    });
    _openPanel();
  }

  void _handleAcknowledgeTicket() {
    widget.onAcknowledgeTicket?.call();
    setState(() {
      _panelState = KitchenTicketPanelState.acknowledged;
      if (_localSelectedTicket?.ticket.ticketNumber == 'T-014' ||
          _displayedTicket?.ticket.ticketNumber == 'T-014' ||
          widget.selectedTicket?.ticket.ticketNumber == 'T-014') {
        _localSelectedTicket = KitchenBoardSampleData.t014Acknowledged;
        _displayedTicket = KitchenBoardSampleData.t014Acknowledged;
      }
    });
  }

  void _handleBeginPreparation() {
    widget.onBeginPreparation?.call();
    setState(() {
      _panelState = KitchenTicketPanelState.preparing;
      if (_localSelectedTicket?.ticket.ticketNumber == 'T-014' ||
          _displayedTicket?.ticket.ticketNumber == 'T-014' ||
          widget.selectedTicket?.ticket.ticketNumber == 'T-014') {
        _localSelectedTicket = KitchenBoardSampleData.t014Preparing;
        _displayedTicket = KitchenBoardSampleData.t014Preparing;
      }
    });
  }

  void _handleSendToQC() {
    widget.onSendToQC?.call();
    setState(() {
      _panelState = KitchenTicketPanelState.qualityCheck;
      if (_localSelectedTicket?.ticket.ticketNumber == 'T-014' ||
          _displayedTicket?.ticket.ticketNumber == 'T-014' ||
          widget.selectedTicket?.ticket.ticketNumber == 'T-014') {
        _localSelectedTicket = KitchenBoardSampleData.t014Checking;
        _displayedTicket = KitchenBoardSampleData.t014Checking;
      }
    });
  }

  void _handlePassQC() {
    widget.onPassQC?.call();
    setState(() {
      _panelState = KitchenTicketPanelState.readyForDispatch;
      if (_localSelectedTicket?.ticket.ticketNumber == 'T-014' ||
          _displayedTicket?.ticket.ticketNumber == 'T-014' ||
          widget.selectedTicket?.ticket.ticketNumber == 'T-014') {
        _localSelectedTicket = KitchenBoardSampleData.t014Ready;
        _displayedTicket = KitchenBoardSampleData.t014Ready;
      }
    });
  }

  void _handleFailQC() {
    widget.onFailQC?.call();
  }

  void _handleContinueToHandover() {
    widget.onContinueToHandover?.call();
    setState(() {
      _panelState = KitchenTicketPanelState.photoRequired;
      if (_localSelectedTicket?.ticket.ticketNumber == 'T-014' ||
          _displayedTicket?.ticket.ticketNumber == 'T-014' ||
          widget.selectedTicket?.ticket.ticketNumber == 'T-014') {
        _localSelectedTicket = KitchenBoardSampleData.t014Ready;
        _displayedTicket = KitchenBoardSampleData.t014Ready;
      }
    });
  }

  void _handleAddPhoto() {
    widget.onAddPhoto?.call();
  }

  void _handleClosePanel() {
    widget.onClosePanel?.call();
    _closePanel();
  }

  void _closePanel() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _panelController.value = 0.0;
      if (mounted) {
        setState(() {
          _localSelectedTicket = null;
          _displayedTicket = null;
          _manuallyDismissed = true;
        });
      }
    } else {
      _panelController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _localSelectedTicket = null;
            _displayedTicket = null;
            _manuallyDismissed = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablet = context.isKitchenTablet;
    final activeTicket = _activeTicket;

    Widget body;
    if (tablet && activeTicket != null) {
      body = Stack(
        children: [
          _buildBoard(context, tablet),
          // Scrim overlay to darken the kitchen board in the background
          Positioned.fill(
            child: FadeTransition(
              opacity: _scrimAnimation,
              child: GestureDetector(
                key: const ValueKey('kitchen_panel_scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: _handleClosePanel,
                child: const ColoredBox(
                  color: Color(0x52000000),
                ),
              ),
            ),
          ),
          // Right panel spanning from header to bottom and whole right side with slide animation
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 460,
            child: SlideTransition(
              key: const ValueKey('kitchen_panel_slide_transition'),
              position: _slideAnimation,
              child: KitchenTicketDetailPanel(
                ticket: activeTicket,
                panelState: _panelState,
                onClose: _handleClosePanel,
                onAcknowledge: _handleAcknowledgeTicket,
                onBeginPreparation: _handleBeginPreparation,
                onSendToQC: _handleSendToQC,
                onPassQC: _handlePassQC,
                onFailQC: _handleFailQC,
                onContinueToHandover: _handleContinueToHandover,
                onAddPhoto: _handleAddPhoto,
              ),
            ),
          ),
        ],
      );
    } else if (!tablet && activeTicket != null) {
      body = Stack(
        children: [
          _buildBoard(context, tablet),
          Positioned.fill(
            child: SlideTransition(
              key: const ValueKey('kitchen_panel_slide_transition'),
              position: _slideAnimation,
              child: KitchenTicketDetailPanel(
                ticket: activeTicket,
                panelState: _panelState,
                onClose: _handleClosePanel,
                onAcknowledge: _handleAcknowledgeTicket,
                onBeginPreparation: _handleBeginPreparation,
                onSendToQC: _handleSendToQC,
                onPassQC: _handlePassQC,
                onFailQC: _handleFailQC,
                onContinueToHandover: _handleContinueToHandover,
                onAddPhoto: _handleAddPhoto,
              ),
            ),
          ),
        ],
      );
    } else {
      body = _buildBoard(context, tablet);
    }

    final isReady = _panelState == KitchenTicketPanelState.readyForDispatch ||
        _panelState == KitchenTicketPanelState.photoRequired;
    final isQC = _panelState == KitchenTicketPanelState.qualityCheck;
    final isPreparing = _panelState == KitchenTicketPanelState.preparing;

    return KitchenShell(
      selectedDestination: KitchenDestination.orders,
      phoneHeaderBottom: KitchenStageTabs(
        selectedIndex: isReady ? 3 : (isQC ? 2 : (isPreparing ? 1 : 0)),
      ),
      staffRole: isReady
          ? (tablet ? 'Dispatcher · demo' : 'Dispatcher')
          : (isQC
              ? (tablet ? 'QC checker · demo' : 'QC scenario')
              : 'Kitchen staff'),
      staffStatus: isReady
          ? (tablet ? 'Access policy pending' : 'Access TBD')
          : (isQC
              ? (tablet ? 'Access policy pending' : 'Access TBD')
              : (tablet ? 'Authorized workspace' : 'Authorized')),
      body: body,
    );
  }

  Widget _buildBoard(BuildContext context, bool tablet) {
    final isReady = _panelState == KitchenTicketPanelState.readyForDispatch ||
        _panelState == KitchenTicketPanelState.photoRequired;
    final isQC = _panelState == KitchenTicketPanelState.qualityCheck;
    final isPreparing = _panelState == KitchenTicketPanelState.preparing;
    final isAcknowledged = _panelState == KitchenTicketPanelState.acknowledged;

    final effectiveNewOrders = (isReady || isQC || isPreparing)
        ? const [KitchenBoardSampleData.t018]
        : (isAcknowledged
            ? const [
                KitchenBoardSampleData.t014Acknowledged,
                KitchenBoardSampleData.t018,
              ]
            : KitchenBoardSampleData.newOrders);

    final effectiveCooking = (isReady || isQC)
        ? const [
            KitchenBoardSampleData.t015,
            KitchenBoardSampleData.t019,
          ]
        : (isPreparing
            ? const [
                KitchenBoardSampleData.t014Preparing,
                KitchenBoardSampleData.t015,
                KitchenBoardSampleData.t019,
              ]
            : KitchenBoardSampleData.cooking);

    final effectiveQualityCheck = isReady
        ? const [
            KitchenBoardSampleData.t016,
            KitchenBoardSampleData.t020,
          ]
        : (isQC
            ? const [
                KitchenBoardSampleData.t014Checking,
                KitchenBoardSampleData.t016,
                KitchenBoardSampleData.t020,
              ]
            : KitchenBoardSampleData.qualityCheck);

    final effectiveReady = isReady
        ? const [
            KitchenBoardSampleData.t014Ready,
            KitchenBoardSampleData.t017,
            KitchenBoardSampleData.t021,
          ]
        : KitchenBoardSampleData.ready;

    final effectiveActivePhoneTicket = isReady
        ? KitchenBoardSampleData.t014Ready
        : (isQC
            ? KitchenBoardSampleData.t014Checking
            : (isPreparing
                ? KitchenBoardSampleData.t014Preparing
                : (isAcknowledged
                    ? KitchenBoardSampleData.t014Acknowledged
                    : KitchenBoardSampleData.t014)));

    final effectiveUpNextPhoneTicket = isReady
        ? KitchenBoardSampleData.t017
        : (isQC
            ? KitchenBoardSampleData.t016
            : (isPreparing
                ? KitchenBoardSampleData.t015
                : KitchenBoardSampleData.t018));

    final effectivePhoneStageTitle = isReady
        ? 'READY'
        : (isQC
            ? 'QUALITY CHECK'
            : (isPreparing ? 'COOKING' : 'NEW ORDERS'));

    final effectivePhoneStageCount = (isReady || isQC || isPreparing) ? '03' : '02';

    return SingleChildScrollView(
      padding: EdgeInsets.all(tablet ? 24 : KitchenSpace.md),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: KitchenMetrics.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tablet) ...[
                const KitchenBoardHeading(
                  title: 'Kitchen Board',
                  subtitle:
                      'All permitted brands · live ticket workflow (sample data)',
                  trailing: KitchenSampleBadge(),
                ),
                SizedBox(height: KitchenSpace.md),
                KitchenFilterBar(
                  trailing: Text(
                    'FIGMA QA · T-014 / T-019 / T-020 interactive; other ticket actions are disabled samples.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: context.kitchenTextMuted,
                        ),
                  ),
                ),
                SizedBox(height: KitchenSpace.md),
              ] else ...[
                const KitchenBoardHeading(
                  title: 'Ticket queue',
                  subtitle: 'Shared kitchen · permitted brands',
                ),
                SizedBox(height: KitchenSpace.md),
              ],
              switch (widget.viewState) {
                KitchenTicketsViewState.active => tablet
                    ? KitchenBoardTabletView(
                        newOrders: effectiveNewOrders,
                        cooking: effectiveCooking,
                        qualityCheck: effectiveQualityCheck,
                        ready: effectiveReady,
                        onTicketAction: _handleTicketAction,
                      )
                    : KitchenBoardPhoneView(
                        stageTitle: effectivePhoneStageTitle,
                        stageCount: effectivePhoneStageCount,
                        activeTicket: effectiveActivePhoneTicket,
                        upNextTicket: effectiveUpNextPhoneTicket,
                        onTicketAction: _handleTicketAction,
                      ),
                KitchenTicketsViewState.loading =>
                  LoadingQueueView(wide: tablet),
                KitchenTicketsViewState.empty =>
                  EmptyQueueView(wide: tablet),
              },
            ],
          ),
        ),
      ),
    );
  }
}
