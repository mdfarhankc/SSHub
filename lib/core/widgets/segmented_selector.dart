import 'package:flutter/material.dart';
import 'package:sshub/core/theme/app_theme.dart';

class SegmentedSelector<T> extends StatelessWidget {
  final List<(T value, IconData icon, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool shrinkWrap;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = options.indexWhere((o) => o.$1 == value);
    final x = options.length == 1
        ? 0.0
        : -1.0 + 2 * index / (options.length - 1);

    final selector = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                widthFactor: 1 / options.length,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
          Row(children: [for (final o in options) _segment(context, o)]),
        ],
      ),
    );

    return shrinkWrap ? IntrinsicWidth(child: selector) : selector;
  }

  Widget _segment(
    BuildContext context,
    (T value, IconData icon, String label) option,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = option.$1 == value;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(option.$1),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(option.$2, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(option.$3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
