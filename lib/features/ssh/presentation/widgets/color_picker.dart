import 'package:flutter/material.dart';
import 'package:sshub/core/theme/server_colors.dart';

class ColorPicker extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onSelected;
  const ColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: .centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Swatch(
            color: theme.colorScheme.onSurfaceVariant,
            selected: selected == null,
            icon: Icons.format_color_reset_outlined,
            onTap: () => onSelected(null),
          ),
          for (final value in ServerColors.palette)
            _Swatch(
              color: Color(value),
              selected: selected == value,
              onTap: () => onSelected(value),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: .circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                )
              : null,
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: Theme.of(context).colorScheme.surface)
            : selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
