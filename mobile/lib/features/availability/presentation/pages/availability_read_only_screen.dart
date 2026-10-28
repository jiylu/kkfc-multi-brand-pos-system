import 'package:flutter/material.dart';

import 'package:mobile/features/availability/data/seed/sample_availability_item.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_row.dart';
import 'package:mobile/features/availability/presentation/widgets/note_banner.dart';
import 'package:mobile/features/availability/presentation/widgets/operational_context_card.dart';
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
      actionLabel: 'Back to menu',
      onAction: () {},
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
        const NoteBanner(
          message:
              'SAMPLE DATA · Inventory status and permission rules '
              'require API validation.',
        ),
      ],
      sideCard: const OperationalContextCard(
        title: 'Operational context',
        fields: [
          ContextField('ROLE', 'View only · D-03', emphasized: true),
          ContextField('WORKFLOW', 'availability view'),
          ContextField(
            'IMPLEMENTATION NOTE',
            'This is a read-only view. Use Availability Management to make changes.',
          ),
        ],
      ),
    );
  }
}
