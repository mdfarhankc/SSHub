import 'package:flutter/material.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class AuthTypeSelector extends StatelessWidget {
  final AuthType value;
  final ValueChanged<AuthType> onChanged;
  const AuthTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _types = [
    (AuthType.password, Icons.vpn_key_outlined, "Password"),
    (AuthType.key, Icons.key_outlined, "SSH Key"),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = _types.indexWhere((t) => t.$1 == value);
    final x = -1.0 + 2 * index / (_types.length - 1);

    return Container(
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
                widthFactor: 1 / _types.length,
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
              for (final t in _types) _segment(context, t.$1, t.$2, t.$3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    AuthType type,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = type == value;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(type),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
