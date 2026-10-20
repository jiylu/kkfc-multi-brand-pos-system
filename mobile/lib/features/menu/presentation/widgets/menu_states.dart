import 'package:flutter/material.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/presentation/widgets/responsive_card_grid.dart';

class MenuGridSkeleton extends StatefulWidget {
  const MenuGridSkeleton({super.key});

  @override
  State<MenuGridSkeleton> createState() => _MenuGridSkeletonState();
}

class _MenuGridSkeletonState extends State<MenuGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double h, {double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(MenuRadius.sm),
          ),
        );

    return Semantics(
      label: 'Loading menu',
      child: FadeTransition(
        opacity: _opacity,
        child: ResponsiveCardGrid(
          itemCount: 8,
          itemBuilder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(MenuRadius.md),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MenuSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(aspectRatio: 16 / 10, child: bar(double.infinity)),
                  const SizedBox(height: MenuSpace.md),
                  bar(14, w: 90),
                  const SizedBox(height: MenuSpace.sm),
                  bar(10),
                  const SizedBox(height: MenuSpace.md),
                  bar(14, w: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuMessageCard extends StatelessWidget {
  const MenuMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MenuSpace.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(MenuRadius.md),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(MenuSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(height: MenuSpace.md),
                  Text(title,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: MenuSpace.xs),
                  Text(body,
                      style: text.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: MenuSpace.lg),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}