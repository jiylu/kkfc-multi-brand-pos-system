import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menu/data/models/menu_models.dart';
import 'package:mobile/features/menu/presentation/menu_layout.dart';
import 'package:mobile/features/menu/providers/menu_providers.dart';

class ChannelTabs extends ConsumerWidget {
  const ChannelTabs({super.key, this.inverted = false});

  final bool inverted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(menuChannelProvider);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inverted
              ? scheme.onInverseSurface.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(MenuRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MenuSpace.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final channel in MenuChannel.values)
                _ChannelTab(
                  channel: channel,
                  selected: channel == selected,
                  inverted: inverted,
                  onTap: () =>
                      ref.read(menuChannelProvider.notifier).select(channel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTab extends StatelessWidget {
  const _ChannelTab({
    required this.channel,
    required this.selected,
    required this.onTap,
    this.inverted = false,
  });

  final MenuChannel channel;
  final bool selected;
  final VoidCallback onTap;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.labelLarge!;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(MenuRadius.sm),
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.motion(MenuMotion.medium),
          curve: MenuMotion.curve,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: MenuSpace.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (inverted ? scheme.onInverseSurface : scheme.surface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(MenuRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: context.motion(MenuMotion.fast),
                curve: MenuMotion.curve,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: MenuSpace.xs),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: inverted ? scheme.inverseSurface : scheme.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedDefaultTextStyle(
                duration: context.motion(MenuMotion.fast),
                style: base.copyWith(
                  color: selected
                      ? (inverted ? scheme.inverseSurface : scheme.onSurface)
                      : (inverted
                          ? scheme.onInverseSurface.withValues(alpha: 0.7)
                          : scheme.onSurfaceVariant),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(channel.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}