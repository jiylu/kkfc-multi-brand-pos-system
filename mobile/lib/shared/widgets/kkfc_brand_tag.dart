import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

class KkfcBrandTag extends StatelessWidget {
  const KkfcBrandTag({
    super.key,
    required this.label,
    this.logoAsset,
  });

  final String label;

  /// e.g. 'assets/brands/gamcheon.png'. Null shows the placeholder.
  final String? logoAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(KkfcRadius.md),
          border: Border.all(
            color: scheme.outlineVariant,
            width: KkfcBorderWidth.thin,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KkfcSpace.s8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandLogo(asset: logoAsset),
              const SizedBox(width: KkfcSpace.s16),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: KkfcSpace.s8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.asset});

  final String? asset;

  // Measured from the design: Gamcheon is a ~40px circle, the other two
  // are wide wordmarks. Fixed height, width follows the image.
  static const double _height = 40;
  static const double _maxWidth = 128;

  @override
  Widget build(BuildContext context) {
    const placeholder = _LogoPlaceholder(size: _height);
    final path = asset;
    if (path == null) return placeholder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Image.asset(
        path,
        height: _height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(KkfcRadius.sm),
      ),
      child: Icon(
        Icons.image_outlined,
        size: size / 2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}