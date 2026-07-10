import 'package:flutter/material.dart';
import 'package:sshub/core/theme/app_theme.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool success = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  final foreground = success ? scheme.onInverseSurface : scheme.onError;
  _show(
    context,
    message,
    background: success ? scheme.inverseSurface : scheme.error,
    foreground: foreground,
    leading: Icon(
      success
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
      color: foreground,
      size: 20,
    ),
  );
}

// Persistent spinner toast; stays until another snackbar replaces it.
void showAppLoadingSnackBar(BuildContext context, String message) {
  final scheme = Theme.of(context).colorScheme;
  _show(
    context,
    message,
    background: scheme.inverseSurface,
    foreground: scheme.onInverseSurface,
    duration: const Duration(days: 1),
    leading: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: scheme.onInverseSurface,
      ),
    ),
  );
}

void _show(
  BuildContext context,
  String message, {
  required Widget leading,
  required Color background,
  required Color foreground,
  Duration? duration,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        content: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
}
