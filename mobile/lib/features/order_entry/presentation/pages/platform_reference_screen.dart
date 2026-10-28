import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/shared/widgets/fade_slide_in.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/features/order_entry/data/models/platform_reference_view_data.dart';
import '../widgets/order_entry_header.dart';
import '../widgets/order_entry_action_bar.dart';
import '../widgets/order_context_card.dart';
import '../widgets/platform_reference_card.dart';

class PlatformReferenceScreen extends StatelessWidget {
  const PlatformReferenceScreen({
    super.key,
    this.data = PlatformReferenceViewData.sample,
    this.onEditReferences,
  });

  final PlatformReferenceViewData data;
  final VoidCallback? onEditReferences;

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

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(KkfcSpace.s32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: _Enter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(
                              index: 0,
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
                                  Expanded(
                                    flex: 3,
                                    child: FadeSlideIn(
                                      index: 1,
                                      child: PlatformReferenceCard(data: data),
                                    ),
                                  ),
                                  const SizedBox(width: KkfcSpace.s32),
                                  Expanded(
                                    flex: 2,
                                    child: FadeSlideIn(
                                      index: 2,
                                      child: OrderContextCard(
                                        brand: 'Aurelia’s Inasal',
                                        channelLine: 'GrabFood',
                                        orderStatus: 'Draft',
                                        paymentStatus: 'Unpaid',
                                        note: data.rightSubtitle,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              FadeSlideIn(
                                index: 1,
                                child: PlatformReferenceCard(data: data),
                              ),
                              const SizedBox(height: KkfcSpace.s16),
                              FadeSlideIn(
                                index: 2,
                                child: OrderContextCard(
                                  brand: 'Aurelia’s Inasal',
                                  channelLine: 'GrabFood',
                                  orderStatus: 'Draft',
                                  paymentStatus: 'Unpaid',
                                  note: data.rightSubtitle,
                                ),
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
          FadeSlideIn(
            index: 3,
            child: OrderEntryActionBar(
              secondaryLabel: '',
              primaryLabel: data.buttonLabel,
              isLoading: false,
              onSecondary: null,
              onPrimary: onEditReferences,
              sideBySide: false,
            ),
          ),
        ],
      ),
    );
  }
}

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
