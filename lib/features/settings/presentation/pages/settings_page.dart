import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/page_title.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/about_card.dart';
import 'package:sshub/features/settings/presentation/widgets/backup_card.dart';
import 'package:sshub/features/settings/presentation/widgets/danger_zone.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_card.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';
import 'package:sshub/features/settings/presentation/widgets/theme_selector.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const route = "/settings";
  static const _fontFamilies = [
    "JetBrains Mono",
    "monospace",
    "Consolas",
    "Courier New",
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();
    final auth = sl<LocalAuthService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: CustomScrollView(
            slivers: [
              const LargeHeaderSliver("Settings"),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SettingsCard(
                      icon: Icons.palette_outlined,
                      title: "Appearance",
                      description: "Customize how SSHub looks.",
                      children: [
                        SettingsRow(
                          title: "App Theme",
                          subtitle:
                              "Choose between light, dark, or system theme.",
                          control: ThemeSelector(
                            value: settings.themeMode,
                            onChanged: cubit.updateThemeMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: Icons.terminal_outlined,
                      title: "Terminal",
                      description: "Tune the terminal typeface and size.",
                      children: [
                        SettingsRow(
                          title: "Font Family",
                          subtitle: "Select the typeface for the terminal.",
                          control: SizedBox(
                            width: 180,
                            child: DropdownMenu<String>(
                              expandedInsets: EdgeInsets.zero,
                              requestFocusOnTap: false,
                              initialSelection:
                                  _fontFamilies.contains(
                                    settings.terminalFontFamily,
                                  )
                                  ? settings.terminalFontFamily
                                  : _fontFamilies.first,
                              inputDecorationTheme: const InputDecorationTheme(
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onSelected: (f) {
                                if (f != null) {
                                  cubit.updateTerminalFontFamily(f);
                                }
                              },
                              dropdownMenuEntries: _fontFamilies
                                  .map(
                                    (f) =>
                                        DropdownMenuEntry(value: f, label: f),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SettingsDivider(),
                        SettingsRow(
                          title: "Font Size",
                          subtitle: "Adjust the terminal text size.",
                          stack: true,
                          trailing: Text(
                            "${settings.terminalFontSize.toInt()} pt",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          control: Slider(
                            value: settings.terminalFontSize,
                            min: 10,
                            max: 24,
                            divisions: 14,
                            onChanged: cubit.updateTerminalFontSize,
                          ),
                        ),
                      ],
                    ),
                    if (!Platform.isLinux) ...[
                      const SizedBox(height: 16),
                      SettingsCard(
                        icon: Icons.security_outlined,
                        title: "Security",
                        description: "Lock the app and gate secret reveals.",
                        children: [
                          SettingsRow(
                            title: "App Lock",
                            subtitle:
                                "Protect SSHub with biometric or device lock.",
                            keepInline: true,
                            control: Switch(
                              value: settings.appLockEnabled,
                              onChanged: (value) async {
                                if (value) {
                                  cubit.enableAppLock();
                                } else if (await auth.authenticate(
                                  "Disable app lock",
                                )) {
                                  cubit.disableAppLock();
                                }
                              },
                            ),
                          ),
                          if (settings.appLockEnabled) ...[
                            const SettingsDivider(),
                            SettingsRow(
                              title: "Lock Password Reveal",
                              subtitle:
                                  "Authenticate before viewing saved passwords.",
                              keepInline: true,
                              control: Switch(
                                value: settings.lockPasswordReveal,
                                onChanged: cubit.updateLockPasswordReveal,
                              ),
                            ),
                            const SettingsDivider(),
                            SettingsRow(
                              title: "Lock Snippet Reveal",
                              subtitle:
                                  "Authenticate before viewing saved snippet values.",
                              keepInline: true,
                              control: Switch(
                                value: settings.lockSnippetReveal,
                                onChanged: cubit.updateLockSnippetReveal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const BackupCard(),
                    const SizedBox(height: 16),
                    const AboutCard(),
                    const SizedBox(height: 24),
                    const DangerZone(),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
