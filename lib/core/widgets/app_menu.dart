import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sshub/core/theme/app_theme.dart';

// One action in an app menu: a label, a trailing icon, an optional keyboard
// hint, and a destructive flag that tints it as a warning.
class ContextMenuAction {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final bool destructive;
  const ContextMenuAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.hint,
    this.destructive = false,
  });
}

// The shared menu surface used by both the lifted context menu and the plain
// cursor menu, so every menu in the app looks the same.
class AppMenu extends StatelessWidget {
  final List<ContextMenuAction> actions;
  final ValueChanged<ContextMenuAction> onSelected;
  final double width;
  const AppMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.width = 240,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
              _row(context, actions[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ContextMenuAction action) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = action.destructive ? scheme.error : scheme.onSurface;
    return InkWell(
      onTap: () => onSelected(action),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ),
            if (action.hint != null) ...[
              const SizedBox(width: 16),
              Text(
                action.hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(width: 12),
            Icon(action.icon, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

// Shows [actions] as a plain menu anchored at [globalPosition] with no blurred
// backdrop, for quick cursor menus like the terminal right-click. Uses the same
// surface as the lifted context menu so the two look identical.
Future<void> showAppMenu({
  required BuildContext context,
  required Offset globalPosition,
  required List<ContextMenuAction> actions,
}) {
  if (actions.isEmpty) return Future.value();
  final overlay = Overlay.of(context);
  final size = (overlay.context.findRenderObject() as RenderBox).size;
  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppMenuPopup(
      globalPosition: globalPosition,
      overlaySize: size,
      actions: actions,
      onClose: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _AppMenuPopup extends StatefulWidget {
  final Offset globalPosition;
  final Size overlaySize;
  final List<ContextMenuAction> actions;
  final VoidCallback onClose;
  const _AppMenuPopup({
    required this.globalPosition,
    required this.overlaySize,
    required this.actions,
    required this.onClose,
  });

  @override
  State<_AppMenuPopup> createState() => _AppMenuPopupState();
}

class _AppMenuPopupState extends State<_AppMenuPopup>
    with SingleTickerProviderStateMixin {
  static const _menuWidth = 240.0;
  static const _rowHeight = 48.0;
  static const _margin = 12.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Plays the exit before running an action, so the menu never vanishes in a
  // single frame.
  Future<void> _close([VoidCallback? then]) async {
    await _controller.reverse();
    widget.onClose();
    then?.call();
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.globalPosition;
    final size = widget.overlaySize;
    final menuHeight = widget.actions.length * _rowHeight;

    // Below the cursor when it fits, otherwise above it.
    final fitsBelow = pos.dy + menuHeight < size.height - _margin;
    final top = fitsBelow ? pos.dy : pos.dy - menuHeight;
    var left = pos.dx;
    if (left + _menuWidth > size.width - _margin) {
      left = size.width - _margin - _menuWidth;
    }
    if (left < _margin) left = _margin;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _close(),
            onSecondaryTap: () => _close(),
          ),
        ),
        Positioned(
          left: left,
          top: top.clamp(_margin, size.height - _margin),
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, child) {
              final t = _t.value.clamp(0.0, 1.0);
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.95 + 0.05 * t,
                  alignment: fitsBelow
                      ? Alignment.topLeft
                      : Alignment.bottomLeft,
                  child: child,
                ),
              );
            },
            child: AppMenu(
              width: _menuWidth,
              actions: widget.actions,
              onSelected: (a) => _close(a.onPressed),
            ),
          ),
        ),
      ],
    );
  }
}
