import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - MenuSpace.lg * 2;
        final columns = (usable / MenuLayout.minCardWidth).floor().clamp(2, 5);
        final rows = (itemCount / columns).ceil();

        return ListView.builder(
          padding: const EdgeInsets.all(MenuSpace.lg),
          itemCount: rows,
          itemBuilder: (context, row) {
            final cells = <Widget>[];
            for (var col = 0; col < columns; col++) {
              final index = row * columns + col;
              if (col > 0) cells.add(const SizedBox(width: MenuSpace.md));
              cells.add(
                Expanded(
                  child: index < itemCount
                      ? itemBuilder(context, index)
                      : const SizedBox.shrink(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: MenuSpace.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cells,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
