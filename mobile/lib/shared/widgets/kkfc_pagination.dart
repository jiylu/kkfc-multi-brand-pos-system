import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

class KkfcPagination extends StatelessWidget {
  const KkfcPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.showFirstLast = false,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool showFirstLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final canGoPrevious = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s16,
        vertical: KkfcSpace.s16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showFirstLast)
            IconButton(
              tooltip: 'First page',
              onPressed: canGoPrevious ? () => onPageChanged(1) : null,
              icon: const Icon(Icons.first_page),
            ),
          TextButton.icon(
            onPressed:
                canGoPrevious ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: KkfcSpace.s24),
          Text(
            'Page $currentPage of $totalPages',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: KkfcSpace.s24),
          TextButton.icon(
            onPressed: canGoNext ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
          ),
          if (showFirstLast)
            IconButton(
              tooltip: 'Last page',
              onPressed: canGoNext ? () => onPageChanged(totalPages) : null,
              icon: const Icon(Icons.last_page),
            ),
        ],
      ),
    );
  }
}
