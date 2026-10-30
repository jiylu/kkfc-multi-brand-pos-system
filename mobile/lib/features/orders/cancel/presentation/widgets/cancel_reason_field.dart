import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/shared/shared_layout.dart';

/// Cancellation reason input from design frames 10-11.
///
/// The label sits inside the bordered box, the character counter and the
/// helper/error line sit below it, and the border switches to the error look
/// on the server-side validation step.
class CancelReasonField extends StatefulWidget {
  const CancelReasonField({
    super.key,
    required this.controller,
    required this.maxLength,
    this.errorText,
    this.helperText,
    this.hintText,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final int maxLength;

  /// When non-null the field shows the error look and this message instead of
  /// [helperText].
  final String? errorText;

  final String? helperText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<CancelReasonField> createState() => _CancelReasonFieldState();
}

class _CancelReasonFieldState extends State<CancelReasonField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? scheme.error
        : _focusNode.hasFocus
        ? scheme.primary
        : scheme.outlineVariant;
    final borderWidth = _focusNode.hasFocus || hasError
        ? MenuBorder.thick
        : MenuBorder.thin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MenuSpace.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(MenuRadius.md),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancellation reason *',
                style: text.labelLarge?.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: MenuSpace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  maxLines: 4,
                  maxLength: widget.maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  style: text.bodyLarge,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MenuSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.errorText ?? widget.helperText ?? '',
                style: text.bodySmall?.copyWith(
                  color: hasError ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: MenuSpace.md),
            Text(
              '${widget.controller.text.length} / ${widget.maxLength}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
