import 'package:flutter/material.dart';

// Primary-coloured screen header title.
class PageTitle extends StatelessWidget {
  final String text;
  final TextStyle? base;

  const PageTitle(this.text, {super.key, this.base});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: (base ?? theme.textTheme.titleLarge)?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

// Collapsing large app bar for top-level screens.
class LargeHeaderSliver extends StatelessWidget {
  final String title;

  const LargeHeaderSliver(this.title, {super.key});

  @override
  Widget build(BuildContext context) =>
      SliverAppBar.large(pinned: true, title: PageTitle(title));
}
