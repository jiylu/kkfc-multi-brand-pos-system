import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_metrics.dart';
import 'package:mobile/roles/kitchen_staff/shared/kitchen_palette.dart';

/// Uppercase segmented tabs on navy. Peach = selected.
/// [expand] true stretches segments to fill width (phone stage tabs).
class KitchenSegmentTabs extends StatelessWidget {
  const KitchenSegmentTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onSelected,
    this.expand = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (var i = 0; i < labels.length; i++)
        _Segment(
          label: labels[i],
          selected: i == selectedIndex,
          onTap: onSelected == null ? null : () => onSelected!(i),
        ),
    ];
    final row = IntrinsicHeight(
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final s in segments) expand ? Expanded(child: s) : s],
      ),
    );
    if (expand) return row;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.kitchenOnSelected
        : context.kitchenOnChrome;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? context.kitchenSelected : context.kitchenChromeRaised,
        borderRadius: BorderRadius.circular(KitchenRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: KitchenMetrics.controlHeight,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: KitchenSpace.lg),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
