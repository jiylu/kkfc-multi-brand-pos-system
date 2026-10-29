import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/presentation/widgets/animated_peso.dart';
import 'package:mobile/shared/widgets/menu_header.dart';
import 'package:mobile/shared/widgets/menu_navigation.dart';
import 'package:mobile/features/new_order/presentation/widgets/repricing/operational_context_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/repricing/repricing_notice.dart';
import 'package:mobile/features/new_order/presentation/widgets/repricing/repricing_row.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

class ChannelRepricingScreen extends StatelessWidget {
  const ChannelRepricingScreen({super.key});

  void _openSection(BuildContext context, int index) {
    if (index == 1) {
      context.go(AppRoutes.orders);
    } else if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit is not available yet.')),
      );
    } else {
      context.go(AppRoutes.menu);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KkfcScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showRail = width >= MenuLayout.compactMax;
          final showContext = width >= MenuLayout.compactMax;

          return Column(
            children: [
              const MenuHeader(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showRail)
                      MenuRail(
                        onSelected: (index) => _openSection(context, index),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _RepricingBody(showContext: showContext),
                          ),
                          const _GotItBar(),
                          if (!showRail)
                            MenuBottomNav(
                              onSelected: (index) =>
                                  _openSection(context, index),
                            ),
                        ],
                      ),
                    ),
                    if (showContext) ...[
                      const VerticalDivider(width: 1),
                      const SizedBox(
                        width: MenuLayout.cartPanelWidth,
                        child: OperationalContextCard(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RepricingBody extends ConsumerWidget {
  const _RepricingBody({required this.showContext});

  final bool showContext;

  String _lineDetail(CartLine line, MenuChannel channel) {
    final unit = formatPeso(line.item.priceFor(channel));
    final delta = modifiersCentavosFor(line.item, line.selections);

    if (delta == 0) return '${line.quantity} × $unit';

    final sign = delta > 0 ? '+' : '−';
    return '${line.quantity} × ($unit $sign ${formatPeso(delta.abs())})';
  }

  void _undo(BuildContext context, WidgetRef ref) {
    final restored = ref.read(menuChannelProvider.notifier).undo();
    if (!restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous channel to restore.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(menuChannelProvider);
    final lines = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final compact = MediaQuery.sizeOf(context).width < MenuLayout.compactMax;
    final title = compact
        ? '${channel.label} prices updated'
        : 'Prices updated for ${channel.label}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        MenuSpace.lg,
        MenuSpace.lg,
        MenuSpace.lg,
        MenuSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: MenuSpace.xs),
          Text(
            'Channel change and undo',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: MenuSpace.lg),
          const RepricingNotice(
            title: 'Channel prices recalculated',
            body: 'SAMPLE PRICES · Undo restores the previous channel.',
          ),
          const SizedBox(height: MenuSpace.lg),
          RepricingRow(
            title: 'Selected channel',
            subtitle: channel.label,
            emphasiseSubtitle: true,
            trailing: const _SelectedBadge(),
          ),
          const SizedBox(height: MenuSpace.sm),
          for (final line in lines) ...[
            RepricingRow(
              title: '${line.quantity} × ${line.item.name}',
              subtitle: _lineDetail(line, channel),
              trailing: _ValuePill(
                child: Text(
                  formatPeso(line.totalCentavos(channel)),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: MenuSpace.sm),
          ],
          RepricingRow(
            title: 'Repriced total',
            subtitle: '$count items',
            trailing: _ValuePill(
              child: AnimatedPeso(
                centavos: total,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: MenuSpace.sm),
          RepricingRow(
            title: 'Undo',
            subtitle: 'Restore previous channel',
            trailing: FilledButton.tonal(
              onPressed: () => _undo(context, ref),
              child: const Text('Undo'),
            ),
          ),
          if (showContext) ...[const SizedBox(height: MenuSpace.lg)],
        ],
      ),
    );
  }
}

class _GotItBar extends StatelessWidget {
  const _GotItBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(MenuSpace.md),
        child: KkfcLoadingButton(
          label: 'Got it',
          loadingLabel: 'Clearing…',
          isLoading: false, // TODO: wire to the real sending state once the backend exists.
          onPressed: () => context.go(AppRoutes.menu),
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuSpace.md,
        vertical: MenuSpace.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: child,
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuSpace.md,
        vertical: MenuSpace.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: Text(
        'Selected',
        style: text.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
