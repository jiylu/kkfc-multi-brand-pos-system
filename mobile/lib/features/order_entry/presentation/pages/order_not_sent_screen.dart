import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import '../../data/models/order_not_sent_view_data.dart';
import '../widgets/draft_safe_card.dart';
import '../widgets/order_not_sent_context_card.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_entry_header.dart';
import '../widgets/status_tag.dart';
import '../widgets/tone_notice.dart';

class OrderNotSentScreen extends StatelessWidget {
  const OrderNotSentScreen({
    super.key,
    this.data = OrderNotSentViewData.sample,
    this.onEditOrder,
    this.onRetrySafely,
    this.isRetrying = false,
  });

  final OrderNotSentViewData data;
  final VoidCallback? onEditOrder;
  final VoidCallback? onRetrySafely;
  final bool isRetrying;

  static const double _twoColumnBreakpoint = 720;

  void _handleEditOrder(BuildContext context) {
    if (onEditOrder != null) {
      onEditOrder!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (router != null) {
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
    final danger = context.semanticColors.danger;

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
                                tone: danger,
                              ),
                              title: wide ? data.title : data.compactTitle,
                              subtitle: data.subtitle,
                              trailing: wide
                                  ? Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: danger.bg,
                                        borderRadius: BorderRadius.circular(
                                          KkfcRadius.lg,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.cancel_outlined,
                                        color: danger.fg,
                                        size: 28,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: KkfcSpace.s32),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DraftSafeCard(
                                      data: data,
                                      compact: false,
                                    ),
                                  ),
                                  const SizedBox(width: KkfcSpace.s32),
                                  Expanded(
                                    flex: 2,
                                    child: OrderNotSentContextCard(
                                      data: data,
                                      tone: danger,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              DraftSafeCard(data: data, compact: true),
                              const SizedBox(height: KkfcSpace.s16),
                              ToneNotice(
                                body: data.noticeBody,
                                tone: danger,
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
            isLoading: isRetrying,
            secondaryLabel: data.secondaryLabel,
            primaryLabel: data.primaryLabel,
            onSecondary: () => _handleEditOrder(context),
            onPrimary: onRetrySafely,
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
