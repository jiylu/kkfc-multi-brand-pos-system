import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/design_only_example_card.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_queue_panel.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/no_active_tickets_pill.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/queue_clear_header.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/refresh_queue_button.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/what_happens_next_card.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// The "Empty queue" state. [wide] = tablet two-column, otherwise phone stack.
class EmptyQueueView extends StatelessWidget {
  const EmptyQueueView({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const QueueClearHeader(),
        SizedBox(height: KitchenSpace.md),
        Text(
          'There are no confirmed orders in the selected brand/channel queue.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.kitchenTextMuted),
        ),
        SizedBox(height: KitchenSpace.lg),
        const WhatHappensNextCard(),
        SizedBox(height: KitchenSpace.lg),
        wide
            ? const Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(child: RefreshQueueButton()),
              )
            : const RefreshQueueButton(fullWidth: true),
      ],
    );

    return KitchenQueuePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NoActiveTicketsPill(),
          SizedBox(height: KitchenSpace.lg),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: main),
                SizedBox(width: KitchenSpace.lg),
                const Expanded(flex: 2, child: DesignOnlyExampleCard()),
              ],
            )
          else
            main,
        ],
      ),
    );
  }
}