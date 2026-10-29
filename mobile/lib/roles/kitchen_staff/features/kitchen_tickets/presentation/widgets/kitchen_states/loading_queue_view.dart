import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/queue_state_layout.dart';

/// "Loading tickets" state (design frame 26). Action stays disabled.
class LoadingQueueView extends StatelessWidget {
  const LoadingQueueView({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return QueueStateLayout(
      wide: wide,
      tone: context.semanticColors.info,
      statusLabel: 'SYNC IN PROGRESS',
      headerIcon: Symbols.radio_button_unchecked,
      title: 'Loading Kitchen tickets',
      description:
          'Fetching current tickets. Totals, timers and actions are not yet confirmed.',
      nextMessage:
          'Prevent actions until the initial server response identifies ticket state.',
      exampleTitle: 'Waiting for ticket data',
      exampleMessage:
          'Action buttons remain unavailable until the queue finishes loading.',
      actionLabel: 'Loading...',
      // onAction omitted: button is disabled while loading.
    );
  }
}