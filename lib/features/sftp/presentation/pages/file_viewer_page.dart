import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/presentation/cubit/file_viewer_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class FileViewerPage extends StatelessWidget {
  const FileViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewer = context.read<FileViewerCubit>();
    final file = viewer.file;

    return BlocBuilder<FileViewerCubit, FileViewerState>(
      builder: (context, state) {
        final isText = state.status == FileViewerStatus.ready;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _subtitle(state, file.size),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              if (isText)
                IconButton(
                  tooltip: "Copy all",
                  icon: const Icon(LucideIcons.files),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: state.text));
                    if (context.mounted) {
                      showAppSnackBar(context, "Copied to the clipboard");
                    }
                  },
                ),
              IconButton(
                tooltip: "Download",
                icon: const Icon(LucideIcons.download),
                // Pops first so the transfer bar on the browser is visible.
                onPressed: () {
                  final browser = context.read<SftpCubit>();
                  Navigator.pop(context);
                  browser.download(file);
                },
              ),
              IconButton(
                tooltip: "Reload",
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: viewer.load,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: switch (state.status) {
            FileViewerStatus.loading => const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            FileViewerStatus.failure => _Message(
              icon: LucideIcons.circleAlert,
              iconColor: scheme.error,
              title: "Could not read this file",
              detail: state.errorMessage ?? "",
              onRetry: viewer.load,
            ),
            FileViewerStatus.binary => _Message(
              icon: LucideIcons.braces,
              iconColor: scheme.onSurfaceVariant,
              title: "Not a text file",
              detail:
                  "This looks like binary data. Download it to open it in "
                  "another program.",
            ),
            FileViewerStatus.ready => Column(
              // Scaffold passes loose constraints, and a SingleChildScrollView
              // shrink-wraps under those, so the body would end up only as wide
              // as the longest line.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.truncated)
                  const _TruncatedBanner(shown: FileViewerCubit.maxBytes),
                Expanded(child: _TextBody(text: state.text)),
              ],
            ),
          },
        );
      },
    );
  }

  static String _subtitle(FileViewerState state, int size) =>
      switch (state.status) {
        FileViewerStatus.ready =>
          "${formatBytes(size)}  ·  ${state.lineCount} lines",
        _ => formatBytes(size),
      };
}

class _TextBody extends StatelessWidget {
  final String text;
  const _TextBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Long lines scroll rather than wrap.
    return Scrollbar(
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: AppTheme.mono,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TruncatedBanner extends StatelessWidget {
  final int shown;
  const _TruncatedBanner({required this.shown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Showing the first ${formatBytes(shown)}. Download the file to "
              "see the rest.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text("Try Again"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
