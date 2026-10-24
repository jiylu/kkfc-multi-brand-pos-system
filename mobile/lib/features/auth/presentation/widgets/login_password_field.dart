import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/widgets/kkfc_text_field.dart';

class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return KkfcTextField(
      label: 'Password',
      hint: 'Enter password',
      controller: widget.controller,
      obscureText: !_visible,
      autocorrect: false,
      enabled: widget.enabled,
      hasError: widget.hasError,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.only(right: KkfcSpace.s8),
          child: TextButton(
            onPressed: widget.enabled
                ? () => setState(() => _visible = !_visible)
                : null,
            child: Text(_visible ? 'Hide' : 'Show'),
          ),
        ),
      ),
    );
  }
}