import 'package:flutter/material.dart';

import 'package:sshub/features/settings/domain/entities/app_settings.dart';

// Three tappable cards, each a small mock of the app in that theme, matching
// the desktop settings pattern. System shows light and dark split down the
// middle.
class ThemePreviewCards extends StatelessWidget {
  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  const ThemePreviewCards({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _light = _Palette(
    background: Color(0xFFE9EFEC),
    sidebar: Color(0xFFF4F7F5),
    panel: Color(0xFFFFFFFF),
    bar: Color(0xFFD4DED9),
  );
  static const _dark = _Palette(
    background: Color(0xFF0A0E0D),
    sidebar: Color(0xFF101917),
    panel: Color(0xFF141C1A),
    bar: Color(0xFF2A332F),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _card(context, AppThemeMode.system, "System")),
        const SizedBox(width: 16),
        Expanded(child: _card(context, AppThemeMode.light, "Light")),
        const SizedBox(width: 16),
        Expanded(child: _card(context, AppThemeMode.dark, "Dark")),
      ],
    );
  }

  Widget _card(BuildContext context, AppThemeMode mode, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == mode;
    final borderWidth = selected ? 2.5 : 1.0;
    final Widget mock = switch (mode) {
      AppThemeMode.light => _mock(_light),
      AppThemeMode.dark => _mock(_dark),
      AppThemeMode.system => Stack(
        children: [
          Positioned.fill(child: _mock(_light)),
          Positioned.fill(
            child: ClipRect(clipper: _RightHalf(), child: _mock(_dark)),
          ),
        ],
      ),
    };

    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(mode),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: borderWidth,
                ),
              ),
              // Clip the child, not the bordered box, so the border corners
              // are not shaved by the clip.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16 - borderWidth),
                child: mock,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Drawn at a fixed 4:3 size and scaled to the card, so the fixed bar heights
  // never overflow a small card on a phone.
  Widget _mock(_Palette p) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 240,
        height: 180,
        child: Container(
          color: p.background,
          padding: const EdgeInsets.all(18),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 44,
                  color: p.sidebar,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _bar(p, 1, height: 7),
                      const SizedBox(height: 8),
                      _bar(p, 1, height: 7),
                      const SizedBox(height: 8),
                      _bar(p, 0.7, height: 7),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(p, 0.5, height: 9),
                        const SizedBox(height: 16),
                        _bar(p, 0.95, height: 6),
                        const SizedBox(height: 9),
                        _bar(p, 0.8, height: 6),
                        const SizedBox(height: 9),
                        _bar(p, 0.85, height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(_Palette p, double widthFactor, {double height = 4}) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: p.bar,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

class _Palette {
  final Color background;
  final Color sidebar;
  final Color panel;
  final Color bar;
  const _Palette({
    required this.background,
    required this.sidebar,
    required this.panel,
    required this.bar,
  });
}

class _RightHalf extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height);

  @override
  bool shouldReclip(_) => false;
}
