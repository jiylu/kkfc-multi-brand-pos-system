import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/features/availability/data/seed/sample_availability_item.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_row.dart';
import 'package:mobile/features/availability/presentation/widgets/note_banner.dart';
import 'package:mobile/features/availability/presentation/widgets/pos_shell.dart';

class AvailabilityReadOnlyScreen extends StatelessWidget {
  const AvailabilityReadOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [...sampleAvailability];

    return PosShell(
      title: 'Availability',
      subtitle: 'Kitchen / FOH · scoped availability',
      staffName: 'Staff',
      staffRole: 'D-03 pending',
      actionLabel: 'Back to ordering',
      onAction: () => context.go(AppRoutes.menu),
      sectionsBuilder: (context, isTablet) => [
        const NoteBanner(
          title: 'Read-only view',
          message:
              'Viewing item availability by channel. '
              'This view is read-only and cannot be modified.',
        ),
        for (final item in items)
          InfoRow(
            title: '${item.name} · ${item.channel.label}',
            subtitle: item.available ? 'Available' : 'Unavailable',
            trailing: StatusChip(item.available ? 'Available' : 'Unavailable'),
          ),
      ],
    );
  }
}
