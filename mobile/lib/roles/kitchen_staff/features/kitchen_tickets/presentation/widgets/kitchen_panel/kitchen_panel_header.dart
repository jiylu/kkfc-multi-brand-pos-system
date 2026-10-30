import 'package:flutter/material.dart';

/// Top header for the kitchen ticket detail panel.
/// Displays stage/status subtitle ("NEW ORDER · QUEUED"),
/// large ticket number ("Ticket T-014"), subtitle ("Ready to acknowledge"),
/// and a close button ("×").
class KitchenPanelHeader extends StatelessWidget {
  const KitchenPanelHeader({
    super.key,
    this.badgeText = 'NEW ORDER · QUEUED',
    this.ticketNumber,
    this.title,
    this.subtitle = 'Ready to acknowledge',
    this.backgroundColor = Colors.white,
    this.badgeColor = const Color(0xFF0284C7),
    this.topAccentColor,
    this.onClose,
  });

  final String badgeText;
  final String? ticketNumber;
  final String? title;
  final String subtitle;
  final Color backgroundColor;
  final Color badgeColor;
  final Color? topAccentColor;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        title ??
        (ticketNumber != null
            ? (ticketNumber!.startsWith('Ticket')
                  ? ticketNumber!
                  : 'Ticket $ticketNumber')
            : 'Ticket T-014');

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: topAccentColor != null
            ? Border(top: BorderSide(color: topAccentColor!, width: 3))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            resolvedTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
