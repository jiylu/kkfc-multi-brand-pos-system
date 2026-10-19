import 'package:flutter/material.dart';

import 'package:mobile/app/theme/tokens.dart';

import 'session_expired_card.dart';
import 'session_expired_copy.dart';
import 'session_expired_layout.dart';
import 'session_expired_motion.dart';

export 'session_expired_card.dart' show SessionExpiredCard;

/// Entry point. Owns the animation controller, responsive gutter, and
/// back-button handling. The caller decides what "Sign in again" does.
class SessionExpiredDialog extends StatefulWidget {
  const SessionExpiredDialog({
    super.key,
    required this.preservedItemCount,
    required this.onSignIn,
  });

  final int preservedItemCount;
  final VoidCallback onSignIn;

  @override
  State<SessionExpiredDialog> createState() => _SessionExpiredDialogState();
}

class _SessionExpiredDialogState extends State<SessionExpiredDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final SessionExpiredMotion _motion;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: KkfcMotion.slow);
    _motion = SessionExpiredMotion(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Respect the OS "remove animations" setting: jump to the end state.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Android back must not dismiss a session prompt
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < SessionExpiredLayout.compactBreakpoint;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(
                compact
                    ? SessionExpiredLayout.gapMd
                    : SessionExpiredLayout.gapXl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: SessionExpiredLayout.dialogMaxWidth,
                ),
                child: SingleChildScrollView(
                  child: SessionExpiredCard(
                    motion: _motion,
                    compact: compact,
                    itemLabel: preservedItemsLabel(widget.preservedItemCount),
                    onSignIn: widget.onSignIn,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Opens the dialog over the current route. Non-dismissible on purpose.
Future<void> showSessionExpiredDialog(
  BuildContext context, {
  required int preservedItemCount,
  required VoidCallback onSignIn,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Session ended',
    barrierColor: scheme.scrim.withValues(alpha: KkfcOpacity.scrim),
    transitionDuration: KkfcMotion.fast,
    pageBuilder: (context, animation, secondaryAnimation) =>
        SessionExpiredDialog(
          preservedItemCount: preservedItemCount,
          onSignIn: onSignIn,
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
