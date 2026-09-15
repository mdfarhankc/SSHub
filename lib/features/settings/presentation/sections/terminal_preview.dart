import 'package:flutter/material.dart';
import 'package:sshub/core/theme/terminal_schemes.dart';
import 'package:xterm/ui.dart';

// A non-interactive sample of the terminal, so the effect of the theme, font
// and size is visible without opening a session. Not the xterm engine, just
// styled text using the same palette a real session would.
class TerminalPreview extends StatelessWidget {
  final String fontFamily;
  final double fontSize;
  final String colorScheme;

  const TerminalPreview({
    super.key,
    required this.fontFamily,
    required this.fontSize,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = TerminalSchemes.resolve(colorScheme, dark: dark);
    // Built the same way a real session builds its text, so the font, size and
    // line height match exactly.
    final style = TerminalStyle(fontSize: fontSize, fontFamily: fontFamily);
    final base = style.toTextStyle(color: t.foreground);

    // Plain text on the scheme's background, the two things SSHub actually
    // controls. Any colour beyond this comes from what the server prints, so the
    // preview does not imply it.
    TextSpan prompt() => TextSpan(text: r"root@prod-web-01:~# ", style: base);

    final lines = <TextSpan>[
      TextSpan(
        children: [
          prompt(),
          TextSpan(text: "ls", style: base),
        ],
      ),
      TextSpan(text: "config.yaml  deploy.log  releases  src", style: base),
      TextSpan(
        children: [
          prompt(),
          TextSpan(text: "cat config.yaml", style: base),
        ],
      ),
      TextSpan(text: "env: production", style: base),
      TextSpan(text: "region: ap-south-1", style: base),
      TextSpan(children: [prompt(), _cursor(t, fontSize)]),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleBar(context, t.background.computeLuminance() < 0.5),
          Padding(
            // Matches the real terminal's padding.
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Text.rich(line, maxLines: 1, overflow: TextOverflow.clip),
              ],
            ),
          ),
        ],
      ),
    );
  }

  WidgetSpan _cursor(TerminalTheme t, double size) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Container(width: size * 0.55, height: size, color: t.foreground),
  );

  Widget _titleBar(BuildContext context, bool dark) {
    final dot = dark ? Colors.white24 : Colors.black26;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: dark ? Colors.white.withValues(alpha: 0.04) : Colors.black12,
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          const Spacer(),
          Text(
            "prod-web-01",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: dark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
