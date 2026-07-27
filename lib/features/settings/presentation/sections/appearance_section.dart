import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/theme/terminal_schemes.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/sections/terminal_preview.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_dropdown.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_group.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_label.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';
import 'package:sshub/features/settings/presentation/widgets/theme_preview_cards.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  // Only bundled families, so every choice renders a real, distinct face.
  static const _fontFamilies = [
    "JetBrains Mono",
    "Source Code Pro",
    "IBM Plex Mono",
    "Ubuntu Mono",
  ];

  static const _scrollbackOptions = [1000, 5000, 10000, 50000, 100000];

  static const _cursorStyles = ["Block", "Bar", "Underline"];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsLabel("Theme"),
        ThemePreviewCards(
          value: settings.themeMode,
          onChanged: cubit.updateThemeMode,
        ),
        const SizedBox(height: 36),
        const SettingsLabel("Preview"),
        TerminalPreview(
          fontFamily: settings.terminalFontFamily,
          fontSize: settings.terminalFontSize,
          colorScheme: settings.terminalColorScheme,
        ),
        const SizedBox(height: 36),
        const SettingsLabel("Terminal"),
        SettingsGroup(
          children: [
            SettingsRow(
              title: "Font family",
              subtitle: "The typeface used in the terminal.",
              control: SettingsDropdown<String>(
                value: _fontFamilies.contains(settings.terminalFontFamily)
                    ? settings.terminalFontFamily
                    : _fontFamilies.first,
                options: [for (final f in _fontFamilies) (f, f)],
                onChanged: cubit.updateTerminalFontFamily,
                leading: (f) => _fontSwatch(context, f),
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Color scheme",
              subtitle: "The terminal palette.",
              control: SettingsDropdown<String>(
                value:
                    TerminalSchemes.names.contains(settings.terminalColorScheme)
                    ? settings.terminalColorScheme
                    : TerminalSchemes.defaultName,
                options: [for (final s in TerminalSchemes.names) (s, s)],
                onChanged: cubit.updateTerminalColorScheme,
                leading: (s) => _schemeSwatch(context, s),
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Scrollback",
              subtitle: "Lines kept in history. Applies to new sessions.",
              control: SettingsDropdown<int>(
                value: _scrollbackOptions.contains(settings.terminalScrollback)
                    ? settings.terminalScrollback
                    : 10000,
                options: [
                  for (final v in _scrollbackOptions)
                    (v, v >= 100000 ? "Unlimited" : "$v lines"),
                ],
                onChanged: cubit.updateTerminalScrollback,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Cursor style",
              subtitle: "How the terminal cursor is drawn.",
              control: SettingsDropdown<String>(
                value: _cursorStyles.contains(settings.cursorStyle)
                    ? settings.cursorStyle
                    : "Block",
                options: [for (final c in _cursorStyles) (c, c)],
                onChanged: cubit.updateCursorStyle,
                width: 160,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Visual bell",
              subtitle: "Flash the terminal when a program rings the bell.",
              keepInline: true,
              control: Switch(
                value: settings.bellVisual,
                onChanged: cubit.updateBellVisual,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Sound bell",
              subtitle: "Play a native beep when a program rings the bell.",
              keepInline: true,
              control: Switch(
                value: settings.bellSound,
                onChanged: cubit.updateBellSound,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Font size",
              subtitle: "The terminal text size.",
              control: SizedBox(
                width: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                          ),
                          child: Slider(
                            value: settings.terminalFontSize,
                            min: 10,
                            max: 24,
                            divisions: 14,
                            onChanged: cubit.previewTerminalFontSize,
                            onChangeEnd: cubit.updateTerminalFontSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 22,
                      child: Text(
                        "${settings.terminalFontSize.toInt()}",
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const SettingsLabel("Behavior"),
        SettingsGroup(
          children: [
            SettingsRow(
              title: "Close session on back",
              subtitle:
                  "Leaving a terminal disconnects it instead of leaving the "
                  "tab open.",
              keepInline: true,
              control: Switch(
                value: settings.closeSessionOnBack,
                onChanged: cubit.updateCloseSessionOnBack,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Copy on select",
              subtitle: "Copy selected text to the clipboard automatically.",
              keepInline: true,
              control: Switch(
                value: settings.copyOnSelect,
                onChanged: cubit.updateCopyOnSelect,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Paste on right-click",
              subtitle: "Right-click pastes instead of opening the menu.",
              keepInline: true,
              control: Switch(
                value: settings.pasteOnRightClick,
                onChanged: cubit.updatePasteOnRightClick,
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              title: "Reduce motion",
              subtitle: "Cut in-app animations and transitions.",
              keepInline: true,
              control: Switch(
                value: settings.reduceMotion,
                onChanged: cubit.updateReduceMotion,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // A tiny "Aa" sample rendered in the font, like the reference.
  Widget _fontSwatch(BuildContext context, String family) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        "Aa",
        style: TextStyle(
          fontFamily: family,
          fontSize: 12,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  // A chip of the palette's background with its red/green/blue accents.
  Widget _schemeSwatch(BuildContext context, String name) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = TerminalSchemes.resolve(name, dark: dark);
    return Container(
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_dot(t.red), _dot(t.green), _dot(t.blue)],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
