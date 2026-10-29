import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/features/availability/data/models/availability_model.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_row.dart';
import 'package:mobile/features/availability/presentation/widgets/note_banner.dart';
import 'package:mobile/features/availability/presentation/widgets/pos_shell.dart';
import 'package:mobile/features/availability/providers/availability_providers.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/menu_channel_mapping.dart';

class AvailabilityReadOnlyScreen extends ConsumerWidget {
  const AvailabilityReadOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(availabilityMenuItemsProvider);

    return PosShell(
      title: 'Availability',
      subtitle: 'Kitchen / FOH · scoped availability',
      staffName: 'Staff',
      staffRole: 'D-03 pending',
      actionLabel: 'Back to ordering',
      onAction: () => context.go(AppRoutes.menu),
      sectionsBuilder: (context, isTablet, channel) {
        final menuChannel = menuChannelForPos(channel);

        return <Widget>[
          const NoteBanner(
            title: 'Read-only view',
            message:
                'Viewing item availability by channel. '
                'This view is read-only and cannot be modified.',
          ),
          ...items.when<List<Widget>>(
            loading: () => const <Widget>[
              NoteBanner(
                title: 'Loading availability',
                message: 'Fetching menu items…',
              ),
            ],
            error: (_, _) => <Widget>[
              InfoRow(
                title: "Couldn't load availability",
                subtitle: 'Check the Wi-Fi, then try again.',
                trailing: TextButton(
                  onPressed: () =>
                      ref.invalidate(availabilityMenuItemsProvider),
                  child: const Text('Try again'),
                ),
              ),
            ],
            data: (menuItems) {
              if (menuItems.isEmpty) {
                return const <Widget>[
                  NoteBanner(
                    title: 'No menu items',
                    message: 'This brand has no menu items to show.',
                  ),
                ];
              }

              return <Widget>[
                for (final item in menuItems)
                  _AvailabilityRow(
                    item: item,
                    channel: channel,
                    menuChannel: menuChannel,
                  ),
              ];
            },
          ),
        ];
      },
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.item,
    required this.channel,
    required this.menuChannel,
  });

  final MenuItem item;
  final PosChannel channel;
  final MenuChannel menuChannel;

  @override
  Widget build(BuildContext context) {
    final availability = item.availabilityFor(menuChannel);

    return InfoRow(
      title: '${item.name} · ${channel.label}',
      subtitle: _detail(item, channel, availability),
      trailing: StatusChip(_label(availability)),
    );
  }

  static String _label(MenuAvailability availability) => switch (availability) {
    MenuAvailability.available => 'Available',
    MenuAvailability.stockout => 'Out of stock',
    MenuAvailability.manualOff => 'Manual unavailable',
    MenuAvailability.inactive => 'Inactive',
  };

  static String _detail(
    MenuItem item,
    PosChannel channel,
    MenuAvailability availability,
  ) => switch (availability) {
    MenuAvailability.available =>
      item.description.isEmpty
          ? 'Available on ${channel.label}'
          : item.description,
    MenuAvailability.stockout => 'Out of stock · shared inventory',
    MenuAvailability.manualOff => 'Unavailable on ${channel.label}',
    MenuAvailability.inactive => 'Not on sale',
  };
}
