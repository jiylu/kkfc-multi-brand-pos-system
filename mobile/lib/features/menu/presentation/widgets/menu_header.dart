import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/channel_tabs.dart';

class MenuHeader extends ConsumerWidget {
  const MenuHeader({super.key, required this.compact});

  /// True on phones: brand and user on one row, tabs on a second row.
  final bool compact;

  void _signOut(WidgetRef ref) {
    final token = ref.read(sessionTokenProvider);
    if (token == null) return;

    unawaited(ref.read(authRepositoryProvider).logout(token));
    ref.read(sessionExpiredProvider.notifier).set(false);
    ref.read(sessionTokenProvider.notifier).setToken(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final themedBrand = OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(Icons.expand_more, color: scheme.onInverseSurface),
      iconAlignment: IconAlignment.end,
      label: Text("Aurelia's Inasal", style: TextStyle(color: scheme.onInverseSurface)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.onInverseSurface.withValues(alpha: 0.5)),
      ),
    );

    final themedUser = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Ana R.', style: text.labelLarge?.copyWith(color: scheme.onInverseSurface)),
        Text('Order staff',
            style: text.labelSmall?.copyWith(color: scheme.onInverseSurface.withValues(alpha: 0.7))),
      ],
    );

    final themedLogout = IconButton(
      tooltip: 'Logout',
      icon: Icon(Icons.logout, color: scheme.onInverseSurface),
      onPressed: () => _signOut(ref),
    );

    return Material(
      color: scheme.inverseSurface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.onInverseSurface.withValues(alpha: 0.2))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MenuSpace.md),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [themedBrand, const Spacer(), themedUser, themedLogout]),
                    const SizedBox(height: MenuSpace.md),
                    const ChannelTabs(inverted: true),
                  ],
                )
              : Row(
                  children: [
                    themedBrand,
                    const SizedBox(width: MenuSpace.lg),
                    const Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ChannelTabs(inverted: true),
                      ),
                    ),
                    const SizedBox(width: MenuSpace.lg),
                    themedUser,
                    const SizedBox(width: MenuSpace.sm),
                    themedLogout,
                  ],
                ),
        ),
      ),
    );
  }
}