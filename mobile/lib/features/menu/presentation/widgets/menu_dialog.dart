import 'package:flutter/material.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';

Future<T?> showMenuDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final scheme = Theme.of(context).colorScheme;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scheme.scrim.withValues(alpha: 0.5),
    transitionDuration: context.motion(MenuMotion.medium),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(child: MenuDialogSurface(child: builder(context))),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MenuMotion.curve,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class MenuDialogSurface extends StatelessWidget {
  const MenuDialogSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(MenuSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Material(
          color: scheme.surface,
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(MenuRadius.lg),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MenuSpace.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
