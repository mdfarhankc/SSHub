import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';

// A compact pill dropdown for a settings row. Opens a frosted, blurred menu
// anchored under the pill. [leading] draws an optional preview swatch beside
// each item, like a font sample or a palette chip.
class SettingsDropdown<T> extends StatefulWidget {
  final T value;
  final List<(T value, String label)> options;
  final ValueChanged<T> onChanged;
  final double width;
  final Widget Function(T value)? leading;

  const SettingsDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.width = 200,
    this.leading,
  });

  @override
  State<SettingsDropdown<T>> createState() => _SettingsDropdownState<T>();
}

class _SettingsDropdownState<T> extends State<SettingsDropdown<T>> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();

  void _toggle() =>
      _controller.isShowing ? _controller.hide() : _controller.show();

  void _select(T value) {
    _controller.hide();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: _buildMenu,
      child: CompositedTransformTarget(
        link: _link,
        child: _Pill(
          label: _currentLabel,
          leading: widget.leading?.call(widget.value),
          width: widget.width,
          onTap: _toggle,
        ),
      ),
    );
  }

  String get _currentLabel => widget.options
      .firstWhere(
        (o) => o.$1 == widget.value,
        orElse: () => widget.options.first,
      )
      .$2;

  Widget _buildMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Tapping anywhere off the menu closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _controller.hide,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Align(
            alignment: Alignment.topLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: widget.width,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: AppTheme.cardShadow(
                      Theme.of(context).brightness,
                      strong: true,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final o in widget.options)
                            _MenuItem(
                              label: o.$2,
                              leading: widget.leading?.call(o.$1),
                              selected: o.$1 == widget.value,
                              onTap: () => _select(o.$1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Widget? leading;
  final double width;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.leading,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              LucideIcons.check,
              size: 16,
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
