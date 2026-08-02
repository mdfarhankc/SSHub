import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_menu.dart';

// ContextMenuAction lives with the shared menu; re-exported so existing callers
// that import it from here keep working.
export 'package:sshub/core/widgets/app_menu.dart' show ContextMenuAction;

// Long-press on touch or right-click on desktop lifts the child above a blurred
// backdrop and shows its actions, the way an iOS context menu does. Pure
// Flutter, so it looks the same on every platform.
class ContextMenuArea extends StatefulWidget {
  final Widget child;
  final List<ContextMenuAction> actions;
  final BorderRadius? borderRadius;
  const ContextMenuArea({
    super.key,
    required this.child,
    required this.actions,
    this.borderRadius,
  });

  @override
  State<ContextMenuArea> createState() => ContextMenuAreaState();
}

class ContextMenuAreaState extends State<ContextMenuArea> {
  final _childKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _active => _entry != null;

  // Public so a button inside the child, like a "more" icon, can open the same
  // menu the long-press and right-click gestures do.
  void open() {
    if (_active || widget.actions.isEmpty) return;
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusXl);

    HapticFeedback.mediumImpact();
    _entry = OverlayEntry(
      builder: (_) => _ContextMenuOverlay(
        anchorRect: rect,
        borderRadius: radius,
        actions: widget.actions,
        onDismiss: _close,
        child: widget.child,
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: open,
      onSecondaryTapDown: (_) => open(),
      // The lifted copy stands in for the child while the menu is open.
      child: Opacity(
        opacity: _active ? 0 : 1,
        child: KeyedSubtree(key: _childKey, child: widget.child),
      ),
    );
  }
}

class _ContextMenuOverlay extends StatefulWidget {
  final Rect anchorRect;
  final BorderRadius borderRadius;
  final List<ContextMenuAction> actions;
  final VoidCallback onDismiss;
  final Widget child;
  const _ContextMenuOverlay({
    required this.anchorRect,
    required this.borderRadius,
    required this.actions,
    required this.onDismiss,
    required this.child,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  static const _menuWidth = 240.0;
  static const _rowHeight = 48.0;
  static const _gap = 12.0;
  static const _margin = 12.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Plays the exit before running an action, so the menu never disappears in a
  // single frame.
  Future<void> _dismiss([VoidCallback? then]) async {
    await _controller.reverse();
    widget.onDismiss();
    then?.call();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final anchor = widget.anchorRect;
    final menuHeight = widget.actions.length * _rowHeight + _gap;

    // Below the preview when it fits, otherwise above it.
    final belowTop = anchor.bottom + _gap;
    final fitsBelow =
        belowTop + menuHeight < size.height - media.padding.bottom - _margin;
    final menuTop = fitsBelow ? belowTop : anchor.top - _gap - menuHeight;

    var menuLeft = anchor.left;
    if (menuLeft + _menuWidth > size.width - _margin) {
      menuLeft = size.width - _margin - _menuWidth;
    }
    if (menuLeft < _margin) menuLeft = _margin;

    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _dismiss(),
                onSecondaryTap: () => _dismiss(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18 * t, sigmaY: 18 * t),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.28 * t),
                  ),
                ),
              ),
            ),
            Positioned(
              left: anchor.left,
              top: anchor.top,
              width: anchor.width,
              height: anchor.height,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: 1 + 0.04 * t,
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: SizedBox(
                      width: anchor.width,
                      height: anchor.height,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: menuLeft,
              top: menuTop,
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.9 + 0.1 * t,
                  alignment: fitsBelow
                      ? Alignment.topLeft
                      : Alignment.bottomLeft,
                  child: AppMenu(
                    width: _menuWidth,
                    actions: widget.actions,
                    onSelected: (a) => _dismiss(a.onPressed),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
