import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';
import 'package:mobile/features/new_order/presentation/widgets/channel_tabs.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/availability/data/models/availability_model.dart';

MenuChannel _menuChannelFor(PosChannel channel) => switch (channel) {
  PosChannel.dineIn => MenuChannel.dineIn,
  PosChannel.takeaway => MenuChannel.takeaway,
  PosChannel.grabFood => MenuChannel.grabFood,
  PosChannel.foodpanda => MenuChannel.foodpanda,
};

PosChannel _posChannelFor(MenuChannel channel) => switch (channel) {
  MenuChannel.dineIn => PosChannel.dineIn,
  MenuChannel.takeaway => PosChannel.takeaway,
  MenuChannel.grabFood => PosChannel.grabFood,
  MenuChannel.foodpanda => PosChannel.foodpanda,
};

class MenuHeader extends ConsumerWidget {
  const MenuHeader({
    super.key,
    this.compact,
    this.channel,
    this.onChannelChanged,
    this.staffName,
    this.staffRole,
  });

  final bool? compact;
  final PosChannel? channel;
  final ValueChanged<PosChannel>? onChannelChanged;
  final String? staffName;
  final String? staffRole;

  void _signOut(WidgetRef ref) {
    final token = ref.read(sessionTokenProvider);
    if (token == null) return;

    unawaited(ref.read(authRepositoryProvider).logout(token));
    ref.read(sessionExpiredProvider.notifier).set(false);
    ref.read(sessionTokenProvider.notifier).setToken(null);
  }

  /// Shows the repricing notice after a channel change when prices differ.
  void _onChannelSelected(BuildContext context, WidgetRef ref) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (GoRouterState.of(context).matchedLocation == AppRoutes.channelChange) {
      return;
    }

    final notifier = ref.read(menuChannelProvider.notifier);
    final previous = notifier.previousChannel;
    final current = ref.read(menuChannelProvider);
    final cart = ref.read(cartProvider);

    if (previous == null || cart.isEmpty) {
      return;
    }

    var hasPriceChange = false;
    for (final line in cart) {
      if (line.totalCentavos(previous) != line.totalCentavos(current)) {
        hasPriceChange = true;
        break;
      }
    }

    if (!hasPriceChange) {
      return;
    }

    router.go(AppRoutes.channelChange);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSession = ref.watch(sessionProvider);
    if (hasSession) {
      ref.listen<AsyncValue<AssignedBrand>>(assignedBrandProvider, (_, next) {
        final b = next.value;
        if (b != null) {
          ref.read(activeBrandProvider.notifier).select(b);
        }
      });
    }

    final AssignedBrand? assignedBrand =
        hasSession ? ref.watch(assignedBrandProvider).value : null;
    final AssignedBrand brand =
        assignedBrand ?? ref.watch(activeBrandProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final themedBrand = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuSpace.sm,
        vertical: MenuSpace.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: BrandLogo(brand: brand, height: MenuSpace.xl),
    );

    final themedUser = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          staffName ?? 'Ana R.',
          style: text.labelLarge?.copyWith(color: scheme.onInverseSurface),
        ),
        Text(
          staffRole ?? 'Order staff',
          style: text.labelSmall?.copyWith(
            color: scheme.onInverseSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );

    final themedLogout = IconButton(
      tooltip: 'Logout',
      icon: Icon(Icons.logout, color: scheme.onInverseSurface),
      onPressed: () => _signOut(ref),
    );

    final Widget channelWidget;
    if (onChannelChanged != null && channel != null) {
      channelWidget = ChannelTabs(
        inverted: true,
        selected: _menuChannelFor(channel!),
        onSelected: (selected) => onChannelChanged!(_posChannelFor(selected)),
      );
    } else {
      channelWidget = ChannelTabs(
        inverted: true,
        onSelected: (_) => _onChannelSelected(context, ref),
      );
    }

    return Material(
      color: scheme.inverseSurface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              compact ?? constraints.maxWidth < MenuLayout.compactMax;

          return Padding(
            padding: const EdgeInsets.all(MenuSpace.md),
            child: isCompact
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(child: themedBrand),
                          const SizedBox(width: MenuSpace.md),
                          Flexible(child: themedUser),
                          const SizedBox(width: MenuSpace.sm),
                          themedLogout,
                        ],
                      ),
                      const SizedBox(height: MenuSpace.md),
                      Center(child: channelWidget),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: themedBrand),
                      const SizedBox(width: MenuSpace.lg),
                      Flexible(child: channelWidget),
                      const SizedBox(width: MenuSpace.lg),
                      themedUser,
                      const SizedBox(width: MenuSpace.sm),
                      themedLogout,
                    ],
                  ),
          );
        },
      ),
    );
  }
}
