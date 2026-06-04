import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DialogField extends StatefulWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String name;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool required;

  const DialogField({
    super.key,
    required this.controller,
    required this.name,
    this.required = true,
    this.hint,
    this.icon,
    this.validator,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction = .next,
    this.onSubmitted,
  });

  @override
  State<DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<DialogField> {
  // Only relevant when obscureText is true: whether the secret is hidden.
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: widget.autofocus,
      controller: widget.controller,
      obscureText: widget.obscureText && _obscured,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.name,
        hintText: widget.hint,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: !widget.obscureText
            ? null
            : IconButton(
                tooltip: _obscured ? "Show password" : "Hide password",
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
      ),
      validator:
          widget.validator ??
          (value) {
            if (!widget.required) return null;
            return (value == null || value.trim().isEmpty)
                ? "${widget.name} is required"
                : null;
          },
    );
  }
}
