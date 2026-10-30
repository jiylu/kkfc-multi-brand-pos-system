import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_board/kitchen_lane_column.dart';

/// 4-lane board layout for tablet.
class KitchenBoardTabletView extends StatelessWidget {
  const KitchenBoardTabletView({
    super.key,
    this.newOrders = KitchenBoardSampleData.newOrders,
    this.cooking = KitchenBoardSampleData.cooking,
    this.qualityCheck = KitchenBoardSampleData.qualityCheck,
    this.ready = KitchenBoardSampleData.ready,
    this.onTicketAction,
  });

  final List<KitchenBoardItem> newOrders;
  final List<KitchenBoardItem> cooking;
  final List<KitchenBoardItem> qualityCheck;
  final List<KitchenBoardItem> ready;
  final void Function(KitchenBoardItem item)? onTicketAction;

  @override
  Widget build(BuildContext context) {
    final lanes = [
      KitchenLaneColumn.newOrders(
        tickets: newOrders,
        onTicketAction: onTicketAction,
      ),
      KitchenLaneColumn.cooking(
        tickets: cooking,
        onTicketAction: onTicketAction,
      ),
      KitchenLaneColumn.qualityCheck(
        tickets: qualityCheck,
        onTicketAction: onTicketAction,
      ),
      KitchenLaneColumn.ready(
        tickets: ready,
        onTicketAction: onTicketAction,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const minLaneWidth = 220.0;
        const laneGap = 12.0;
        const totalMinWidth = minLaneWidth * 4 + laneGap * 3;
        final needsHorizontalScroll = constraints.maxWidth < totalMinWidth;

        final rowContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lanes.length; i++) ...[
              if (i > 0) const SizedBox(width: laneGap),
              needsHorizontalScroll
                  ? SizedBox(width: minLaneWidth, child: lanes[i])
                  : Expanded(child: lanes[i]),
            ],
          ],
        );

        if (needsHorizontalScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: rowContent,
          );
        }

        return rowContent;
      },
    );
  }
}
