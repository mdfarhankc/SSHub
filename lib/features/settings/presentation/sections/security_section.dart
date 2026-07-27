import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_dropdown.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_group.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  static const _autoLockOptions = [
    (0, "Immediately"),
    (1, "After 1 minute"),
    (5, "After 5 minutes"),
    (15, "After 15 minutes"),
    (-1, "Never"),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state.settings;
    final cubit = context.read<SettingsCubit>();
    final auth = sl<LocalAuthService>();

    return SettingsGroup(
      children: [
        SettingsRow(
          title: "App lock",
          subtitle: "Protect SSHub with biometric or device lock.",
          keepInline: true,
          control: Switch(
            value: settings.appLockEnabled,
            onChanged: (value) => _toggleLock(context, cubit, auth, value),
          ),
        ),
        if (Platform.isAndroid) ...[
          const SettingsDivider(),
          SettingsRow(
            title: "Block screenshots",
            subtitle:
                "Hide SSHub from screenshots and the recent apps preview.",
            keepInline: true,
            control: Switch(
              value: settings.blockScreenshots,
              onChanged: cubit.updateBlockScreenshots,
            ),
          ),
        ],
        if (settings.appLockEnabled) ...[
          const SettingsDivider(),
          SettingsRow(
            title: "Auto-lock",
            subtitle: "Re-lock after this long away or idle.",
            control: SettingsDropdown<int>(
              value: _autoLockOptions.any((o) => o.$1 == settings.autoLockMinutes)
                  ? settings.autoLockMinutes
                  : 0,
              options: _autoLockOptions,
              onChanged: cubit.updateAutoLockMinutes,
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            title: "Lock password reveal",
            subtitle: "Authenticate before viewing saved passwords.",
            keepInline: true,
            control: Switch(
              value: settings.lockPasswordReveal,
              onChanged: cubit.updateLockPasswordReveal,
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            title: "Lock snippet reveal",
            subtitle: "Authenticate before viewing saved snippet values.",
            keepInline: true,
            control: Switch(
              value: settings.lockSnippetReveal,
              onChanged: cubit.updateLockSnippetReveal,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleLock(
    BuildContext context,
    SettingsCubit cubit,
    LocalAuthService auth,
    bool value,
  ) async {
    if (!value) {
      // Unavailable still disables, or the setting could never be turned off.
      if (await auth.authenticate("Disable app lock") != AuthResult.failed) {
        cubit.disableAppLock();
      }
      return;
    }
    final result = await auth.authenticate("Enable app lock");
    if (!context.mounted) return;
    switch (result) {
      case AuthResult.success:
        cubit.enableAppLock();
      case AuthResult.unavailable:
        showAppSnackBar(
          context,
          "Set a screen lock on this device first. "
          "SSHub cannot verify you without one.",
          success: false,
        );
      case AuthResult.failed:
        break;
    }
  }
}
