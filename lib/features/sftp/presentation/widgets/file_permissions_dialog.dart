import 'package:flutter/material.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

// The chosen permissions plus the selected owner and group ids.
typedef PermissionEdit = ({int permissions, int? uid, int? gid});

// Edits a file's permissions as an rwx grid and its owner/group as pickers.
// Returns the chosen values, or null when cancelled.
class FilePermissionsDialog extends StatefulWidget {
  final RemoteFile file;
  final SftpCubit cubit;
  const FilePermissionsDialog({
    super.key,
    required this.file,
    required this.cubit,
  });

  static Future<PermissionEdit?> show(
    BuildContext context,
    RemoteFile file,
    SftpCubit cubit,
  ) => showDialog<PermissionEdit>(
    context: context,
    builder: (_) => FilePermissionsDialog(file: file, cubit: cubit),
  );

  @override
  State<FilePermissionsDialog> createState() => _FilePermissionsDialogState();
}

class _FilePermissionsDialogState extends State<FilePermissionsDialog> {
  // 0o644 is a sane default when the server did not report the current bits.
  late int _perms = widget.file.permissions ?? 0x1A4;
  late int? _uid = widget.file.uid;
  late int? _gid = widget.file.gid;

  Map<int, String> _users = const {};
  Map<int, String> _groups = const {};
  bool _loadingOwners = true;

  @override
  void initState() {
    super.initState();
    widget.cubit.ownerOptions().then((options) {
      if (!mounted) return;
      setState(() {
        _users = options.users;
        _groups = options.groups;
        _loadingOwners = false;
      });
    });
  }

  void _toggle(int bit) => setState(() => _perms ^= bit);

  Widget _scopeRow(String label, int rBit, int wBit, int xBit) => _ScopeRow(
    label: label,
    read: (_perms & rBit) != 0,
    write: (_perms & wBit) != 0,
    execute: (_perms & xBit) != 0,
    onRead: () => _toggle(rBit),
    onWrite: () => _toggle(wBit),
    onExecute: () => _toggle(xBit),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(child: Text("Permissions")),
          Text(
            _perms.toRadixString(8).padLeft(3, '0'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: AppTheme.mono,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OwnerPicker(
              label: "Owner",
              names: _users,
              value: _uid,
              loading: _loadingOwners,
              onChanged: (value) => setState(() => _uid = value),
            ),
            const SizedBox(height: 8),
            _OwnerPicker(
              label: "Group",
              names: _groups,
              value: _gid,
              loading: _loadingOwners,
              onChanged: (value) => setState(() => _gid = value),
            ),
            const SizedBox(height: 20),
            const _HeaderRow(),
            _scopeRow("Owner", 0x100, 0x80, 0x40),
            _scopeRow("Group", 0x20, 0x10, 0x8),
            _scopeRow("Other", 0x4, 0x2, 0x1),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            permissions: _perms,
            uid: _uid,
            gid: _gid,
          )),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}

class _OwnerPicker extends StatelessWidget {
  final String label;
  final Map<int, String> names;
  final int? value;
  final bool loading;
  final ValueChanged<int?> onChanged;
  const _OwnerPicker({
    required this.label,
    required this.names,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = names.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final items = [
      // Keep the current id selectable even when it is not a named account.
      if (value != null && !names.containsKey(value))
        DropdownMenuItem(value: value, child: Text(value.toString())),
      for (final entry in entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ];
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        Expanded(
          child: DropdownButton<int>(
            isExpanded: true,
            value: value,
            items: items,
            hint: Text(loading ? "Loading..." : "unknown"),
            onChanged: loading ? null : onChanged,
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        const SizedBox(width: 64),
        for (final column in ["Read", "Write", "Exec"])
          Expanded(child: Center(child: Text(column, style: style))),
      ],
    );
  }
}

class _ScopeRow extends StatelessWidget {
  final String label;
  final bool read;
  final bool write;
  final bool execute;
  final VoidCallback onRead;
  final VoidCallback onWrite;
  final VoidCallback onExecute;
  const _ScopeRow({
    required this.label,
    required this.read,
    required this.write,
    required this.execute,
    required this.onRead,
    required this.onWrite,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Checkbox(value: read, onChanged: (_) => onRead())),
        Expanded(child: Checkbox(value: write, onChanged: (_) => onWrite())),
        Expanded(child: Checkbox(value: execute, onChanged: (_) => onExecute())),
      ],
    );
  }
}
