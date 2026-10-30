import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/queue_state_layout.dart';

/// "Empty queue" state (design frame 25).
class EmptyQueueView extends StatelessWidget {
  const EmptyQueueView({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return QueueStateLayout(
      wide: wide,
      tone: context.semanticColors.success,
      statusLabel: 'NO ACTIVE TICKETS',
      headerIcon: Symbols.check,
      title: 'Queue is clear',
      description:
          'There are no confirmed orders in the selected brand/channel queue.',
      nextMessage:
          'New tickets appear after an order is confirmed by the server.',
      exampleTitle: 'No active tasks',
      exampleMessage:
          'A confirmed empty queue means no pending tickets for these filters. '
          'Check again after new orders arrive.',
      actionLabel: 'Refresh queue',
      onAction: () {}, // static for now
    );
  }
}
