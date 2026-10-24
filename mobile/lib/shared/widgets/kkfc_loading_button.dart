import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

class KkfcLoadingButton extends StatelessWidget {
  const KkfcLoadingButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(KkfcSizing.controlLg),
        disabledBackgroundColor: isLoading ? scheme.primary : null,
        disabledForegroundColor: isLoading ? scheme.onPrimary : null,
      ),
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : KkfcMotion.fast,
        child: isLoading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: KkfcSizing.iconSm,
                    height: KkfcSizing.iconSm,
                    child: CircularProgressIndicator(
                      strokeWidth: KkfcBorderWidth.thick,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: KkfcSpace.s8),
                  Text(loadingLabel),
                ],
              )
            : Text(label, key: const ValueKey('idle')),
      ),
    );
  }
}