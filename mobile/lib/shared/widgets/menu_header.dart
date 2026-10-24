import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/presentation/widgets/brands/brand_logo.dart';
import 'package:mobile/features/new_order/presentation/widgets/channel_tabs.dart';
import 'package:mobile/features/new_order/presentation/brand_switch_flow.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/availability/data/models/availability_model.dart';

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

  /// Shows the repricing notice after a channel change. When the notice is
  /// already on screen the live provider update is enough, so we skip the
  /// redundant navigation.
  void _onChannelSelected(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (GoRouterState.of(context).matchedLocation == AppRoutes.channelChange) {
      return;
    }
    router.go(AppRoutes.channelChange);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(activeBrandProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final themedBrand = OutlinedButton(
      onPressed: () => startBrandSwitch(context, ref),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onInverseSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: MenuSpace.md,
          vertical: MenuSpace.sm,
        ),
        side: BorderSide(color: scheme.onInverseSurface.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MenuRadius.md),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MenuSpace.sm,
                vertical: MenuSpace.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(MenuRadius.sm),
              ),
              child: BrandLogo(brand: brand),
            ),
          ),
          const SizedBox(width: MenuSpace.sm),
          const Icon(Icons.expand_more),
        ],
      ),
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

    Widget channelWidget;
    if (onChannelChanged != null && channel != null) {
      // Simple channel display when used by PosShell
      channelWidget = IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MenuSpace.md,
            vertical: MenuSpace.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MenuRadius.md),
            color: scheme.surface.withValues(alpha: 0.1),
          ),
          child: Text(
            channel!.label,
            style: text.labelLarge?.copyWith(color: scheme.onInverseSurface),
          ),
        ),
      );
    } else {
      channelWidget = IntrinsicWidth(
        child: ChannelTabs(
          inverted: true,
          onSelected: (_) => _onChannelSelected(context),
        ),
      );
    }

    return Material(
      color: scheme.inverseSurface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = compact ?? constraints.maxWidth < MenuLayout.compactMax;

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
                          themedUser,
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
