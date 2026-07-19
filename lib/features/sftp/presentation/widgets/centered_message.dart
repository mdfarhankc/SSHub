import 'package:flutter/material.dart';

// Shared frame for the browser's loading, failure and empty states.
class CenteredMessage extends StatelessWidget {
  final Widget child;
  const CenteredMessage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}
