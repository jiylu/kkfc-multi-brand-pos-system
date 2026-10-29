import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/empty_queue_view.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board_heading.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_filter_bar.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_states/kitchen_sample_badge.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_stage_tabs.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_breakpoints.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_destination.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_shell.dart';

/// Kitchen Board (tablet) / Ticket queue (phone). Static empty-queue state.
class KitchenTicketsPage extends StatelessWidget {
  const KitchenTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = context.isKitchenTablet;
    return KitchenShell(
      selectedDestination: KitchenDestination.orders,
      phoneHeaderBottom: const KitchenStageTabs(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tablet ? KitchenSpace.xl : KitchenSpace.md),
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
                  SizedBox(height: KitchenSpace.lg),
                  const KitchenFilterBar(),
                  SizedBox(height: KitchenSpace.md),
                ] else ...[
                  const KitchenBoardHeading(
                    title: 'Ticket queue',
                    subtitle: 'Shared kitchen · permitted brands',
                  ),
                  SizedBox(height: KitchenSpace.md),
                ],
                EmptyQueueView(wide: tablet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}