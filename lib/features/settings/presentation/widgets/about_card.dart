import 'package:flutter/material.dart';
import 'package:sshub/core/app_info.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_card.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/update_check_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  Future<void> _openGithub(BuildContext context) async {
    final uri = Uri.parse("https://github.com/mdfarhankc");
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showAppSnackBar(context, "Could not open link", success: false);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, "Could not open link", success: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SettingsCard(
      icon: Icons.info_outline_rounded,
      title: "About",
      description: "App details and updates.",
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.asset(
                  "assets/icon/icon_without_bg.png",
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SSHub",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Version $appVersion",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SettingsDivider(),
        const UpdateCheckTile(),
        const SettingsDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Designed and built by",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Mohammed Farhan K C",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _openGithub(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "github.com/mdfarhankc",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
