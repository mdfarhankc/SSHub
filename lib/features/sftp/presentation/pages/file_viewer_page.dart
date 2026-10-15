import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/format/byte_size.dart';
import 'package:sshub/core/security/secure_platform.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/sftp/presentation/cubit/file_viewer_cubit.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class FileViewerPage extends StatefulWidget {
  const FileViewerPage({super.key});

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  final TextEditingController _controller = TextEditingController();
  bool _editing = false;
  // The buffer edits with \n; the original EOL is reapplied on save so a
  // Windows file is not silently rewritten with Unix line endings.
  bool _usesCrlf = false;
  // The last saved buffer, normalised to \n, to tell whether there are edits.
  String _savedText = "";

  FileViewerCubit get _viewer => context.read<FileViewerCubit>();

  bool get _dirty => _editing && _controller.text != _savedText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing(FileViewerState state) {
    _usesCrlf = state.text.contains('\r\n');
    final normalised =
        _usesCrlf ? state.text.replaceAll('\r\n', '\n') : state.text;
    _controller.text = normalised;
    _savedText = normalised;
    setState(() => _editing = true);
  }

  void _onEditPressed(FileViewerState state) {
    if (state.truncated) {
      showAppSnackBar(
        context,
        "This file is too large to edit; only the start is loaded.",
      );
      return;
    }
    if (context.read<SftpCubit>().state.readOnly) {
      showAppSnackBar(context, "Turn off read-only mode to edit this file.");
      return;
    }
    _startEditing(state);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Discard changes?"),
        content: const Text("Your edits to this file have not been saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Keep editing"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Discard"),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancelEditing() async {
    if (await _confirmDiscard() && mounted) setState(() => _editing = false);
  }

  Future<void> _save() async {
    final normalised = _controller.text;
    final payload =
        _usesCrlf ? normalised.replaceAll('\n', '\r\n') : normalised;
    await _viewer.save(payload);
    if (!mounted) return;
    final error = _viewer.state.saveError;
    if (error != null) {
      showAppSnackBar(context, "Could not save: $error");
      return;
    }
    _savedText = normalised;
    setState(() => _editing = false);
    showAppSnackBar(context, "Saved");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final file = _viewer.file;

    return BlocBuilder<FileViewerCubit, FileViewerState>(
      builder: (context, state) {
        final isText = state.status == FileViewerStatus.ready;
        final editing = _editing && isText;
        return PopScope(
          canPop: !_dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (await _confirmDiscard() && mounted) Navigator.pop(context);
          },
          child: Scaffold(
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
                    editing ? "Editing" : _subtitle(state, file.size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: editing
                  ? _editingActions(state)
                  : _viewingActions(context, state, isText),
            ),
            body: editing
                ? _Editor(controller: _controller, onChanged: _onEdited)
                : switch (state.status) {
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
                      onRetry: _viewer.load,
                    ),
                    FileViewerStatus.binary => _Message(
                      icon: LucideIcons.braces,
                      iconColor: scheme.onSurfaceVariant,
                      title: "Not a text file",
                      detail:
                          "This looks like binary data. Download it to open "
                          "it in another program.",
                    ),
                    FileViewerStatus.ready => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.truncated)
                          const _TruncatedBanner(shown: FileViewerCubit.maxBytes),
                        Expanded(child: _TextBody(text: state.text)),
                      ],
                    ),
                  },
          ),
        );
      },
    );
  }

  // Refreshes the Save button's enabled state as the buffer changes.
  void _onEdited() => setState(() {});

  List<Widget> _editingActions(FileViewerState state) => [
    IconButton(
      tooltip: "Cancel",
      icon: const Icon(LucideIcons.x),
      onPressed: state.saving ? null : _cancelEditing,
    ),
    state.saving
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : IconButton(
            tooltip: "Save",
            icon: const Icon(LucideIcons.check),
            onPressed: _dirty ? _save : null,
          ),
    const SizedBox(width: 4),
  ];

  List<Widget> _viewingActions(
    BuildContext context,
    FileViewerState state,
    bool isText,
  ) => [
    if (isText)
      IconButton(
        tooltip: "Edit",
        icon: const Icon(LucideIcons.pencil),
        onPressed: () => _onEditPressed(state),
      ),
    if (isText)
      IconButton(
        tooltip: "Copy all",
        icon: const Icon(LucideIcons.files),
        onPressed: () async {
          await SecurePlatform.copySensitive(state.text);
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
        browser.download(_viewer.file);
      },
    ),
    IconButton(
      tooltip: "Reload",
      icon: const Icon(LucideIcons.refreshCw),
      onPressed: _viewer.load,
    ),
    const SizedBox(width: 4),
  ];

  static String _subtitle(FileViewerState state, int size) =>
      switch (state.status) {
        FileViewerStatus.ready =>
          "${formatBytes(size)}  ·  ${state.lineCount} lines",
        _ => formatBytes(size),
      };
}

class _Editor extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _Editor({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextField(
          controller: controller,
          expands: true,
          maxLines: null,
          minLines: null,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => onChanged(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: AppTheme.mono,
            height: 1.45,
          ),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
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
