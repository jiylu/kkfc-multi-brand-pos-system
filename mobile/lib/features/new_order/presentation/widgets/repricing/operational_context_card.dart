import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class OperationalContextCard extends StatelessWidget {
  const OperationalContextCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MenuSpace.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MenuSpace.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(MenuRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operational context',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: MenuSpace.lg),
            const _ContextBlock(
              label: 'ROLE',
              value: 'Order staff / contextual',
            ),
            const SizedBox(height: MenuSpace.lg),
            const _ContextBlock(label: 'WORKFLOW', value: 'channel repriced'),
            const SizedBox(height: MenuSpace.lg),
            const _ContextBlock(
              label: 'IMPLEMENTATION NOTE',
              value:
                  'Use actual brand/channel data and validate the server '
                  'response. Pending client decisions remain provisional.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextBlock extends StatelessWidget {
  const _ContextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: MenuSpace.xs),
        Text(value, style: text.bodyMedium?.copyWith(color: scheme.onSurface)),
      ],
    );
  }
}
