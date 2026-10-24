import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class NoteBanner extends StatelessWidget {
  const NoteBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MenuSpace.md),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(MenuRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            SizedBox(height: MenuSpace.sm),
          ],
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
