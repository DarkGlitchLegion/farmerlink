import 'package:flutter/material.dart';

import 'auth_text_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Password',
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => AuthTextField(
    controller: widget.controller,
    label: widget.label,
    icon: Icons.lock_outline_rounded,
    validator: widget.validator,
    textInputAction: widget.textInputAction,
    obscureText: _obscure,
    autofillHints: const [AutofillHints.password],
    suffix: IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    ),
  );
}
