import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

class KkfcBrandTag extends StatelessWidget {
  const KkfcBrandTag({
    super.key,
    required this.label,
    this.logoAsset,
    this.compact = false,
  });

  final String label;

  /// e.g. 'assets/brands/gamcheon.png'. Null shows the placeholder.
  final String? logoAsset;

  /// Smaller padding, logo and text for tight spaces like the cart header.
  final bool compact;

  static const double _logoHeight = 40;
  static const double _compactLogoHeight = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final logoHeight = compact ? _compactLogoHeight : _logoHeight;
    final padding = compact ? KkfcSpace.s4 : KkfcSpace.s8;
    final gap = compact ? KkfcSpace.s8 : KkfcSpace.s16;
    final trailing = compact ? KkfcSpace.s4 : KkfcSpace.s8;
    final textStyle = compact
        ? theme.textTheme.labelLarge
        : theme.textTheme.titleMedium;

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(
            compact ? KkfcRadius.sm : KkfcRadius.md,
          ),
          border: Border.all(
            color: scheme.outlineVariant,
            width: KkfcBorderWidth.thin,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BrandLogo(asset: logoAsset, height: logoHeight),
              SizedBox(width: gap),
              Flexible(
                child: Text(
                  label,
                  style: textStyle?.copyWith(color: scheme.onSurface),
                ),
              ),
              SizedBox(width: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.asset, required this.height});

  final String? asset;
  final double height;

  // Measured from the design: Gamcheon is a ~40px circle, the other two
  // are wide wordmarks. Fixed height, width follows the image.
  static const double _maxWidth = 128;

  @override
  Widget build(BuildContext context) {
    final placeholder = _LogoPlaceholder(size: height);
    final path = asset;
    if (path == null) return placeholder;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Image.asset(
        path,
        height: height,
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
