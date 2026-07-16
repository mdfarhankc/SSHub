import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/di/service_locator.dart';
import 'package:sshub/core/update/update_service.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckTile extends StatefulWidget {
  const UpdateCheckTile({super.key});

  @override
  State<UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends State<UpdateCheckTile> {
  final _service = sl<UpdateService>();
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final info = await _service.check();
      if (!mounted) return;
      if (info.updateAvailable) {
        _showUpdateDialog(info);
      } else {
        showAppSnackBar(
          context,
          "You're on the latest version (v${info.currentVersion}).",
        );
      }
    } on UpdateException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, success: false);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          "Could not check for updates.",
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // A short window would otherwise clip the notes and the buttons away.
        scrollable: true,
        title: const Text("Update available"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Version ${info.latestVersion} is available. You have ${info.currentVersion}.",
                style: theme.textTheme.bodyMedium,
              ),
              if (info.notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  "What's new".toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _ReleaseNotesView(notes: info.notes),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              launchUrl(
                Uri.parse(info.url),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: _checking ? null : _check,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              LucideIcons.hardDriveDownload,
              size: 20,
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Check for updates",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_checking)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ReleaseNotesView extends StatelessWidget {
  const _ReleaseNotesView({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = notes.split('\n');
    final children = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 8));
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        children.add(
          Padding(
            padding: EdgeInsets.only(top: children.isEmpty ? 0 : 8, bottom: 4),
            child: Text(
              headingMatch.group(2)!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        continue;
      }

      final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodySmall),
                Expanded(
                  child: Text(
                    bulletMatch.group(1)!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line, style: theme.textTheme.bodySmall),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
