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

/// Kitchen Board (tablet) / Ticket queue (phone). Static states only.
class KitchenTicketsPage extends StatefulWidget {
  const KitchenTicketsPage({
    super.key,
    this.viewState = KitchenTicketsViewState.active,
    this.selectedTicket,
    this.onClosePanel,
    this.onTicketAction,
    this.onAcknowledgeTicket,
  });

  final KitchenTicketsViewState viewState;
  final KitchenBoardItem? selectedTicket;
  final VoidCallback? onClosePanel;
  final void Function(KitchenBoardItem item)? onTicketAction;
  final VoidCallback? onAcknowledgeTicket;

  @override
  State<KitchenTicketsPage> createState() => _KitchenTicketsPageState();
}

class _KitchenTicketsPageState extends State<KitchenTicketsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scrimAnimation;

  KitchenBoardItem? _localSelectedTicket;
  KitchenBoardItem? _displayedTicket;
  bool _manuallyDismissed = false;

  @override
  void initState() {
    super.initState();
    _displayedTicket = widget.selectedTicket;
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
      _manuallyDismissed = false;
    });
    _openPanel();
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
                onClose: _handleClosePanel,
                onAcknowledge: widget.onAcknowledgeTicket,
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
                onClose: _handleClosePanel,
                onAcknowledge: widget.onAcknowledgeTicket,
              ),
            ),
          ),
        ],
      );
    } else {
      body = _buildBoard(context, tablet);
    }

    return KitchenShell(
      selectedDestination: KitchenDestination.orders,
      phoneHeaderBottom: const KitchenStageTabs(),
      body: body,
    );
  }

  Widget _buildBoard(BuildContext context, bool tablet) {
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
                    ? KitchenBoardTabletView(onTicketAction: _handleTicketAction)
                    : KitchenBoardPhoneView(onTicketAction: _handleTicketAction),
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
