import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';

import '../../data/models/order_confirmed_view_data.dart';
import '../widgets/kitchen_handoff_card.dart';
import '../widgets/order_context_card.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_entry_header.dart';
import '../widgets/status_tag.dart';
import '../widgets/tone_notice.dart';

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({
    super.key,
    this.data = OrderConfirmedViewData.sample,
    this.onNewOrder,
    this.onCancel,
  });

  final OrderConfirmedViewData data;
  final VoidCallback? onNewOrder;
  final VoidCallback? onCancel;

  static const double _twoColumnBreakpoint = 720;

  void _handleNewOrder(BuildContext context) {
    if (onNewOrder != null) {
      onNewOrder!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.menu);
    } else {
      Navigator.maybeOf(context)?.maybePop();
    }
  }

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
    final success = context.semanticColors.success;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= _twoColumnBreakpoint;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(KkfcSpace.s32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _Enter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OrderEntryHeader(
                              tag: StatusTag(
                                text: data.tag,
                                tone: success,
                                icon: Icons.check,
                              ),
                              title: wide ? data.title : data.compactTitle,
                              subtitle: data.subtitle,
                            ),
                            const SizedBox(height: KkfcSpace.s32),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: KitchenHandoffCard(
                                      data: data,
                                      compact: false,
                                    ),
                                  ),
                                  const SizedBox(width: KkfcSpace.s32),
                                  Expanded(
                                    flex: 2,
                                    child: OrderContextCard(
                                      brand: data.brand,
                                      channelLine: data.channelLine,
                                      orderStatus: 'CONFIRMED',
                                      paymentStatus: data.paymentStatus,
                                      orderTone: success,
                                      note: data.contextNote,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              KitchenHandoffCard(data: data, compact: true),
                              const SizedBox(height: KkfcSpace.s16),
                              ToneNotice(
                                title: data.noticeTitle,
                                body: data.noticeBody,
                                tone: success,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          OrderEntryActionBar(
            sideBySide: true,
            secondaryLabel: data.secondaryLabel,
            primaryLabel: data.primaryLabel,
            onSecondary: () => _handleNewOrder(context),
            onPrimary: onCancel,
          ),
        ],
      ),
    );
  }
}

/// One-shot fade and slide-up on first build. Skipped when the OS asks for
/// reduced motion.
class _Enter extends StatelessWidget {
  const _Enter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: KkfcMotion.base,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
