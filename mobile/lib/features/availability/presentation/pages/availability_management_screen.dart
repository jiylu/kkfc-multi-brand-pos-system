import 'package:flutter/material.dart';

import '../domain/availability_item.dart';
import '../widgets/availability_row.dart';
import '../widgets/availability_toggle.dart';
import '../widgets/note_banner.dart';
import '../widgets/operational_context_card.dart';
import '../widgets/pos_shell.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends State<AvailabilityManagementScreen> {
  late final List<AvailabilityItem> _items = [...sampleAvailability];

  void _setAvailable(int index, bool value) =>
      setState(() => _items[index] = _items[index].copyWith(available: value));

  @override
  Widget build(BuildContext context) {
    return PosShell(
      title: 'Availability management',
      subtitle: 'Kitchen / FOH · scoped availability',
      staffName: 'Staff',
      staffRole: 'D-03 pending',
      actionLabel: 'Back to menu',
      onAction: () {}, // TODO: navigate back to the menu route
      sectionsBuilder: (context, isTablet) => [
        const NoteBanner(
          title: 'Channel-scoped availability',
          message: 'Authorized role only. Tapping a switch saves that item '
              'and channel immediately; record the actor and time.',
        ),
        for (var i = 0; i < _items.length; i++)
          InfoRow(
            title: '${_items[i].name} · ${_items[i].channel.label}',
            subtitle: _items[i].available
                ? 'Available · switch ON'
                : 'Manual: unavailable · OFF',
            trailing: AvailabilityToggle(
              value: _items[i].available,
              semanticLabel:
                  '${_items[i].name} on ${_items[i].channel.label}',
              onChanged: (v) => _setAvailable(i, v),
            ),
          ),
        const InfoRow(
          title: 'Audit record',
          subtitle: 'Actor, action and timestamp',
          trailing: StatusChip('Tracked'),
        ),
        const NoteBanner(
          message: 'SAMPLE DATA · Inventory status and permission rules '
              'require API validation.',
        ),
      ],
      sideCard: const OperationalContextCard(
        title: 'Operational context',
        fields: [
          ContextField('ROLE', 'Authorized role · D-03', emphasized: true),
          ContextField('WORKFLOW', 'availability editor'),
          ContextField(
            'IMPLEMENTATION NOTE',
            'Inventory stockout cannot be cleared by a manual switch. '
                'Confirm role/brand scopes with Backend.',
          ),
        ],
      ),
    );
  }
}