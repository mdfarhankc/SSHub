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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: icon != null
                ? Icon(icon, size: 12, color: Colors.white)
                : selected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
