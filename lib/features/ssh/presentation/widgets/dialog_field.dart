import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sshub/core/theme/app_theme.dart';

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

  final Future<bool> Function()? onReveal;

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
    this.onReveal,
  });

  @override
  State<DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<DialogField> {
  // Only relevant when obscureText is true: whether the secret is hidden.
  bool _obscured = true;
  bool _revealed = false;
  bool _revealing = false;

  Future<void> _toggleObscured() async {
    if (!_obscured) {
      setState(() => _obscured = true);
      return;
    }
    if (widget.onReveal != null && !_revealed) {
      setState(() => _revealing = true);
      final allowed = await widget.onReveal!();
      if (!mounted) return;
      setState(() {
        _revealing = false;
        if (allowed) {
          _revealed = true;
          _obscured = false;
        }
      });
      return;
    }
    setState(() => _obscured = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: !widget.obscureText
            ? null
            : _revealing
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: _obscured ? "Show password" : "Hide password",
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: _toggleObscured,
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
