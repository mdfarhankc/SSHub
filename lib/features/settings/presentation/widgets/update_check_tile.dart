import 'package:flutter/material.dart';
import 'package:sshub/core/update/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckTile extends StatefulWidget {
  const UpdateCheckTile({super.key});

  @override
  State<UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends State<UpdateCheckTile> {
  final _service = UpdateService();
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final info = await _service.check();
      if (!mounted) return;
      if (info.updateAvailable) {
        _showUpdateDialog(info);
      } else {
        _snack("You're on the latest version (v${info.currentVersion}).");
      }
    } on UpdateException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack("Could not check for updates.");
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _showUpdateDialog(UpdateInfo info) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: Text(info.notes, style: theme.textTheme.bodySmall),
                  ),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.system_update_alt_rounded,
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
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
