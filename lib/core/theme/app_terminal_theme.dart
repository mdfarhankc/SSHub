import 'dart:ui';

import 'package:xterm/ui.dart';

abstract final class AppTerminalTheme {
  static const dark = TerminalTheme(
    cursor: Color(0XAAAEAFAD),
    selection: Color(0XAAAEAFAD),
    foreground: Color(0XFFCCCCCC),
    background: Color(0xFF000000),
    black: Color(0XFF000000),
    red: Color(0XFFCD3131),
    green: Color(0XFF0DBC79),
    yellow: Color(0XFFE5E510),
    blue: Color(0XFF2472C8),
    magenta: Color(0XFFBC3FBC),
    cyan: Color(0XFF11A8CD),
    white: Color(0XFFE5E5E5),
    brightBlack: Color(0XFF666666),
    brightRed: Color(0XFFF14C4C),
    brightGreen: Color(0XFF23D18B),
    brightYellow: Color(0XFFF5F543),
    brightBlue: Color(0XFF3B8EEA),
    brightMagenta: Color(0XFFD670D6),
    brightCyan: Color(0XFF29B8DB),
    brightWhite: Color(0XFFFFFFFF),
    searchHitBackground: Color(0XFFFFFF2B),
    searchHitBackgroundCurrent: Color(0XFF31FF26),
    searchHitForeground: Color(0XFF000000),
  );

  static const light = TerminalTheme(
    cursor: Color(0XAA333333),
    selection: Color(0x550078D7),
    foreground: Color(0XFF333333),
    background: Color(0xFFFFFFFF),
    black: Color(0XFF000000),
    red: Color(0XFFCD3131),
    green: Color(0XFF00BC00),
    yellow: Color(0XFF949800),
    blue: Color(0XFF0451A5),
    magenta: Color(0XFFBC05BC),
    cyan: Color(0XFF0598BC),
    white: Color(0XFF555555),
    brightBlack: Color(0XFF666666),
    brightRed: Color(0XFFCD3131),
    brightGreen: Color(0XFF14CE14),
    brightYellow: Color(0XFFB5BA00),
    brightBlue: Color(0XFF0451A5),
    brightMagenta: Color(0XFFBC05BC),
    brightCyan: Color(0XFF0598BC),
    brightWhite: Color(0XFFA5A5A5),
    searchHitBackground: Color(0XFFFFFF2B),
    searchHitBackgroundCurrent: Color(0XFF31FF26),
    searchHitForeground: Color(0XFF000000),
  );
}
