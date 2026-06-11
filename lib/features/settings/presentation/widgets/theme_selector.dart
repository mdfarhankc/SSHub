import 'package:flutter/material.dart';
import 'package:sshub/features/settings/domain/entities/app_settings.dart';

class ThemeSelector extends StatelessWidget {
  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;
  const ThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _modes = [
    (AppThemeMode.system, Icons.computer, "System"),
    (AppThemeMode.light, Icons.light_mode_outlined, "Light"),
    (AppThemeMode.dark, Icons.dark_mode_outlined, "Dark"),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = _modes.indexWhere((m) => m.$1 == value);
    final x = -1.0 + 2 * index / (_modes.length - 1);

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // The sliding chip that glides to the selected segment.
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(x, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / _modes.length,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final m in _modes) _segment(context, m.$1, m.$2, m.$3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    AppThemeMode mode,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = mode == value;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(mode),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
