import 'package:flutter/material.dart';
import 'package:mobile/app/theme/theme_context.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

class KitchenTicketHeader extends StatelessWidget {
  const KitchenTicketHeader({
    super.key,
    required this.ticketNumber,
    required this.elapsed,
    required this.age,
  });

  final String ticketNumber;
  final Duration elapsed;
  final KitchenTicketAge age;

  static String formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final tone = switch (age) {
      KitchenTicketAge.onTime => colors.ageNormal,
      KitchenTicketAge.dueSoon => colors.ageCaution,
      KitchenTicketAge.late => colors.ageLate,
    };
    final (icon, label) = switch (age) {
      KitchenTicketAge.onTime => (Icons.schedule, 'ON TIME'),
      KitchenTicketAge.dueSoon => (Icons.hourglass_top, 'DUE SOON'),
      KitchenTicketAge.late => (Icons.alarm, 'LATE'),
    };
    final text = Theme.of(context).textTheme;
    final time = formatElapsed(elapsed);

    return Semantics(
      container: true,
      label: '$ticketNumber, $label, $time elapsed',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: KkfcMotion.base,
          color: tone.bg,
          padding: const EdgeInsets.symmetric(
            horizontal: KkfcSpace.s16,
            vertical: KkfcSpace.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      ticketNumber,
                      style: text.headlineMedium?.copyWith(
                        color: tone.fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: KkfcSpace.s8),
                  Text(
                    time,
                    style: text.titleLarge?.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KkfcSpace.s4),
              Row(
                children: [
                  Icon(icon, size: 16, color: tone.fg),
                  const SizedBox(width: KkfcSpace.s4),
                  Text(
                    label,
                    style: text.labelMedium?.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}