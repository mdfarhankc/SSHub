import 'dart:ui';

import 'package:sshub/core/theme/app_terminal_theme.dart';
import 'package:xterm/ui.dart';

// Named terminal palettes. "Default" follows the app's light/dark theme; the
// rest are fixed, well-known schemes that look the same in any app theme.
abstract final class TerminalSchemes {
  static const defaultName = "Default";

  static const names = [
    defaultName,
    "Dracula",
    "Solarized Dark",
    "Solarized Light",
    "Gruvbox Dark",
    "Nord",
  ];

  static TerminalTheme resolve(String name, {required bool dark}) =>
      switch (name) {
        "Dracula" => _dracula,
        "Solarized Dark" => _solarizedDark,
        "Solarized Light" => _solarizedLight,
        "Gruvbox Dark" => _gruvboxDark,
        "Nord" => _nord,
        _ => dark ? AppTerminalTheme.dark : AppTerminalTheme.light,
      };

  static bool isDark(String name) => switch (name) {
    "Solarized Light" => false,
    _ => true,
  };

  static TerminalTheme _base({
    required int cursor,
    required int fg,
    required int bg,
    required int black,
    required int red,
    required int green,
    required int yellow,
    required int blue,
    required int magenta,
    required int cyan,
    required int white,
    required int brightBlack,
    required int brightRed,
    required int brightGreen,
    required int brightYellow,
    required int brightBlue,
    required int brightMagenta,
    required int brightCyan,
    required int brightWhite,
  }) => TerminalTheme(
    cursor: Color(cursor),
    selection: Color(cursor).withValues(alpha: 0.35),
    foreground: Color(fg),
    background: Color(bg),
    black: Color(black),
    red: Color(red),
    green: Color(green),
    yellow: Color(yellow),
    blue: Color(blue),
    magenta: Color(magenta),
    cyan: Color(cyan),
    white: Color(white),
    brightBlack: Color(brightBlack),
    brightRed: Color(brightRed),
    brightGreen: Color(brightGreen),
    brightYellow: Color(brightYellow),
    brightBlue: Color(brightBlue),
    brightMagenta: Color(brightMagenta),
    brightCyan: Color(brightCyan),
    brightWhite: Color(brightWhite),
    searchHitBackground: const Color(0XFFFFFF2B),
    searchHitBackgroundCurrent: const Color(0XFF31FF26),
    searchHitForeground: const Color(0XFF000000),
  );

  static final _dracula = _base(
    cursor: 0xFFF8F8F2,
    fg: 0xFFF8F8F2,
    bg: 0xFF282A36,
    black: 0xFF21222C,
    red: 0xFFFF5555,
    green: 0xFF50FA7B,
    yellow: 0xFFF1FA8C,
    blue: 0xFFBD93F9,
    magenta: 0xFFFF79C6,
    cyan: 0xFF8BE9FD,
    white: 0xFFF8F8F2,
    brightBlack: 0xFF6272A4,
    brightRed: 0xFFFF6E6E,
    brightGreen: 0xFF69FF94,
    brightYellow: 0xFFFFFFA5,
    brightBlue: 0xFFD6ACFF,
    brightMagenta: 0xFFFF92DF,
    brightCyan: 0xFFA4FFFF,
    brightWhite: 0xFFFFFFFF,
  );

  static final _solarizedDark = _base(
    cursor: 0xFF93A1A1,
    fg: 0xFF839496,
    bg: 0xFF002B36,
    black: 0xFF073642,
    red: 0xFFDC322F,
    green: 0xFF859900,
    yellow: 0xFFB58900,
    blue: 0xFF268BD2,
    magenta: 0xFFD33682,
    cyan: 0xFF2AA198,
    white: 0xFFEEE8D5,
    brightBlack: 0xFF002B36,
    brightRed: 0xFFCB4B16,
    brightGreen: 0xFF586E75,
    brightYellow: 0xFF657B83,
    brightBlue: 0xFF839496,
    brightMagenta: 0xFF6C71C4,
    brightCyan: 0xFF93A1A1,
    brightWhite: 0xFFFDF6E3,
  );

  static final _solarizedLight = _base(
    cursor: 0xFF586E75,
    fg: 0xFF657B83,
    bg: 0xFFFDF6E3,
    black: 0xFF073642,
    red: 0xFFDC322F,
    green: 0xFF859900,
    yellow: 0xFFB58900,
    blue: 0xFF268BD2,
    magenta: 0xFFD33682,
    cyan: 0xFF2AA198,
    white: 0xFFEEE8D5,
    brightBlack: 0xFF002B36,
    brightRed: 0xFFCB4B16,
    brightGreen: 0xFF586E75,
    brightYellow: 0xFF657B83,
    brightBlue: 0xFF839496,
    brightMagenta: 0xFF6C71C4,
    brightCyan: 0xFF93A1A1,
    brightWhite: 0xFFFDF6E3,
  );

  static final _gruvboxDark = _base(
    cursor: 0xFFEBDBB2,
    fg: 0xFFEBDBB2,
    bg: 0xFF282828,
    black: 0xFF282828,
    red: 0xFFCC241D,
    green: 0xFF98971A,
    yellow: 0xFFD79921,
    blue: 0xFF458588,
    magenta: 0xFFB16286,
    cyan: 0xFF689D6A,
    white: 0xFFA89984,
    brightBlack: 0xFF928374,
    brightRed: 0xFFFB4934,
    brightGreen: 0xFFB8BB26,
    brightYellow: 0xFFFABD2F,
    brightBlue: 0xFF83A598,
    brightMagenta: 0xFFD3869B,
    brightCyan: 0xFF8EC07C,
    brightWhite: 0xFFEBDBB2,
  );

  static final _nord = _base(
    cursor: 0xFFD8DEE9,
    fg: 0xFFD8DEE9,
    bg: 0xFF2E3440,
    black: 0xFF3B4252,
    red: 0xFFBF616A,
    green: 0xFFA3BE8C,
    yellow: 0xFFEBCB8B,
    blue: 0xFF81A1C1,
    magenta: 0xFFB48EAD,
    cyan: 0xFF88C0D0,
    white: 0xFFE5E9F0,
    brightBlack: 0xFF4C566A,
    brightRed: 0xFFBF616A,
    brightGreen: 0xFFA3BE8C,
    brightYellow: 0xFFEBCB8B,
    brightBlue: 0xFF81A1C1,
    brightMagenta: 0xFFB48EAD,
    brightCyan: 0xFF8FBCBB,
    brightWhite: 0xFFECEFF4,
  );
}
