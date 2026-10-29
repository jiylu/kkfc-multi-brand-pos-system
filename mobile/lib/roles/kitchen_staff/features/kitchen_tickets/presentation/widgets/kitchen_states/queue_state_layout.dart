import 'package:flutter/material.dart';
import 'package:mobile/app/theme/semantic_colors.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/design_only_example_card.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_queue_panel.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/queue_action_button.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/queue_state_header.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/queue_status_pill.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/what_happens_next_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Layout shared by every non-ticket queue state (empty, loading, ...).
/// [wide] = tablet two-column, otherwise phone stack.
class QueueStateLayout extends StatelessWidget {
  const QueueStateLayout({
    super.key,
    required this.wide,
    required this.tone,
    required this.statusLabel,
    required this.headerIcon,
    required this.title,
    required this.description,
    required this.nextMessage,
    required this.exampleTitle,
    required this.exampleMessage,
    required this.actionLabel,
    this.onAction,
  });

  final bool wide;
  final KkfcTone tone;
  final String statusLabel;
  final IconData headerIcon;
  final String title;
  final String description;
  final String nextMessage;
  final String exampleTitle;
  final String exampleMessage;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = QueueActionButton(
      label: actionLabel,
      onPressed: onAction,
      fullWidth: !wide,
    );

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QueueStateHeader(icon: headerIcon, title: title, tone: tone),
        SizedBox(height: KitchenSpace.md),
        Text(
          description,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.kitchenTextMuted),
        ),
        SizedBox(height: KitchenSpace.lg),
        WhatHappensNextCard(message: nextMessage),
        SizedBox(height: KitchenSpace.lg),
        wide
            ? Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(child: action),
              )
            : action,
      ],
    );

    return KitchenQueuePanel(
      tone: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QueueStatusPill(label: statusLabel, tone: tone),
          SizedBox(height: KitchenSpace.lg),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: main),
                SizedBox(width: KitchenSpace.lg),
                Expanded(
                  flex: 2,
                  child: DesignOnlyExampleCard(
                    title: exampleTitle,
                    message: exampleMessage,
                  ),
                ),
              ],
            )
          else
            main,
        ],
      ),
    );
  }
}