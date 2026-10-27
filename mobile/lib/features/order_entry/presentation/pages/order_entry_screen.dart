import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/order_entry/data/models/order_entry_view_data.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_entry_header.dart';
import '../widgets/order_status_panel.dart';
import '../widgets/order_summary_card.dart';

class OrderEntryScreen extends StatelessWidget {
  const OrderEntryScreen({
    super.key,
    this.data = OrderEntryViewData.checkBeforeSending,
  });

  final OrderEntryViewData data;

  static const double _twoColumnBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= MenuLayout.compactMax;

          return Column(
            children: [
              const MenuHeader(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showRail) const MenuRail(),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _buildContent(context)),
                          if (!showRail) const MenuBottomNav(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= _twoColumnBreakpoint;
                final summary = FadeSlideIn(
                  index: 1,
                  child: OrderSummaryCard(data: data),
                );
                final status = FadeSlideIn(
                  index: 2,
                  child: OrderStatusPanel(data: data),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(KkfcSpace.s32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeSlideIn(
                            child: OrderEntryHeader(
                              eyebrow: data.eyebrow,
                              title: data.title,
                              subtitle: data.subtitle,
                            ),
                          ),
                          const SizedBox(height: KkfcSpace.s32),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: summary),
                                const SizedBox(width: KkfcSpace.s32),
                                Expanded(flex: 2, child: status),
                              ],
                            )
                          else ...[
                            summary,
                            const SizedBox(height: KkfcSpace.s16),
                            status,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          FadeSlideIn(
            index: 3,
            child: OrderEntryActionBar(
              secondaryLabel: data.secondaryLabel,
              primaryLabel: data.primaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
