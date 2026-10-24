import 'package:flutter/material.dart';
import 'package:mobile/shared/shared_layout.dart';

class CartPanelHeader extends StatelessWidget {
  const CartPanelHeader({
    super.key,
    required this.referenceLabel,
    required this.canClear,
    required this.onClear,
  });

  final String referenceLabel;
  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MenuSpace.lg,
            MenuSpace.lg,
            MenuSpace.sm,
            MenuSpace.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'New order',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: canClear ? onClear : null,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MenuSpace.lg),
          child: TextField(
            decoration: InputDecoration(
              labelText: referenceLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: MenuSpace.sm),
      ],
    );
  }
}
