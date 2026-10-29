import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Themed logout button extracted from [MenuHeader].
///
/// Handles ending the server session and resetting active order / cart state.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({
    super.key,
    this.color,
    this.tooltip = 'Logout',
    this.onLoggedOut,
    this.constraints,
    this.padding,
  });

  /// Icon color. Defaults to [ColorScheme.onInverseSurface] when null.
  final Color? color;

  /// Tooltip description for accessibility and testing.
  final String tooltip;

  /// Optional callback invoked immediately after sign-out state is dispatched.
  final VoidCallback? onLoggedOut;

  /// Optional constraints for the [IconButton].
  final BoxConstraints? constraints;

  /// Optional padding for the [IconButton].
  final EdgeInsetsGeometry? padding;

  /// Signs out the current session and clears all order, cart, and search state.
  static void signOut(WidgetRef ref) {
    final token = ref.read(sessionTokenProvider);
    if (token == null) return;

    unawaited(ref.read(authRepositoryProvider).logout(token));
    ref.read(cartProvider.notifier).clear();
    ref.read(orderReferenceProvider.notifier).clear();
    ref.read(storeReferenceProvider.notifier).clear();
    ref.read(menuSearchProvider.notifier).clear();
    ref.read(menuChannelProvider.notifier).reset();
    ref.read(sessionExpiredProvider.notifier).set(false);
    ref.read(sessionTokenProvider.notifier).setToken(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onInverseSurface;

    return IconButton(
      tooltip: tooltip,
      constraints: constraints,
      padding: padding,
      icon: Icon(Icons.logout, color: effectiveColor),
      onPressed: () {
        signOut(ref);
        onLoggedOut?.call();
      },
    );
  }
}

/// Alias for [LogoutButton].
typedef ThemedLogoutButton = LogoutButton;
