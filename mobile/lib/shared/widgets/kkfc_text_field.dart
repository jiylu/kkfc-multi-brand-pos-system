import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/semantic_colors.dart';

/// Shared text field: bold label above, outlined field, message below.
///
/// States: default, focused, error, disabled.
class KkfcTextField extends StatelessWidget {
  const KkfcTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.disabledText,
    this.hasError = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.valueStyle,
    this.obscureText = false,
    this.autocorrect = true,
    this.suffix,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Placeholder shown inside the field while it is empty.
  final String? hint;

  /// Shown below the field in the normal state.
  final String? helperText;

  /// When non-null the field shows the error look and this message
  /// replaces the helper text.
  final String? errorText;

  /// Shown inside the field when it is disabled
  /// (e.g. "Not used for GrabFood"). Falls back to [hint].
  final String? disabledText;

  /// Error look (red border) without a message. Useful when the message
  /// is shown elsewhere, e.g. one banner for several fields.
  final bool hasError;

  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// Left-aligned by default. The order reference field passes
  /// [TextAlign.center].
  final TextAlign textAlign;

  /// Defaults to bodyLarge. The order reference field passes the
  /// monospace style from KkfcTypography.
  final TextStyle? valueStyle;

  /// Hides the text (passwords). Also turns off input suggestions.
  final bool obscureText;

  final bool autocorrect;

  /// Widget shown at the end of the field (e.g. a Show/Hide button).
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final hasErrorMessage = errorText != null;
    final showError = hasError || hasErrorMessage;
    final message = errorText ?? helperText;
    final style = valueStyle ?? text.bodyLarge;

    final focusColor = KkfcSemanticColors.light.borderFocus;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(KkfcRadius.lg),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: text.titleSmall?.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: KkfcSpace.s8),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            autocorrect: autocorrect,
            enableSuggestions: !obscureText,
            inputFormatters: inputFormatters,
            textAlign: textAlign,
            style: style,
            decoration: InputDecoration(
              hintText: enabled ? hint : (disabledText ?? hint),
              hintStyle: style?.copyWith(color: scheme.onSurfaceVariant),
              suffixIcon: suffix,
              filled: !enabled,
              fillColor: scheme.surfaceContainerHighest,
              // minHeight, not a fixed height, so large text can grow it.
              constraints: const BoxConstraints(minHeight: KkfcSizing.input),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KkfcSpace.s16,
                vertical: KkfcSpace.s12,
              ),
              enabledBorder: showError
                  ? border(scheme.error, KkfcBorderWidth.thick)
                  : border(scheme.outline, KkfcBorderWidth.thin),
              focusedBorder: showError
                  ? border(scheme.error, KkfcBorderWidth.focus)
                  : border(focusColor, KkfcBorderWidth.focus),
              disabledBorder:
                  border(scheme.outlineVariant, KkfcBorderWidth.thin),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: KkfcSpace.s8),
          Semantics(
            liveRegion: hasErrorMessage,
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : KkfcMotion.fast,
              child: Text(
                message,
                key: ValueKey(message),
                style: text.bodyMedium?.copyWith(
                  color:
                      hasErrorMessage ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}