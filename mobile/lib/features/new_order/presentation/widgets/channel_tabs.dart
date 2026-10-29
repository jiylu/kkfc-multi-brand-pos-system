import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/shared_layout.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class ChannelTabs extends ConsumerWidget {
  const ChannelTabs({
    super.key,
    this.inverted = false,
    this.selected,
    this.onSelected,
  });

  final bool inverted;

  final MenuChannel? selected;

  /// Called after a different channel is selected. Not invoked when the
  /// tapped channel is already active.
  final ValueChanged<MenuChannel>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = selected ?? ref.watch(menuChannelProvider);
    final channels = ref.watch(availableChannelsProvider);
    final scheme = Theme.of(context).colorScheme;

    // If the active channel isn't offered for this brand, fall back to the
    // first one that is, so a tab is always highlighted.
    if (selected == null && !channels.contains(active)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(menuChannelProvider.notifier).select(channels.first);
      });
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: inverted
            ? scheme.onInverseSurface.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MenuRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MenuSpace.xs),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: MenuSpace.xs,
          runSpacing: MenuSpace.xs,
          children: [
            for (final channel in channels)
              _ChannelTab(
                channel: channel,
                selected: channel == active,
                inverted: inverted,
                onTap: () {
                  if (channel == active) return;
                  if (selected == null) {
                    ref.read(menuChannelProvider.notifier).select(channel);
                  }
                  onSelected?.call(channel);
                },
              ),
          ],
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
                          color: inverted
                              ? scheme.inverseSurface
                              : scheme.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Flexible(
                child: AnimatedDefaultTextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
