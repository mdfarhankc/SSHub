import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/auth/reveal_guard.dart';
import 'package:sshub/core/widgets/app_form_sheet.dart';
import 'package:sshub/core/widgets/section_header.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/widgets/auth_type_selector.dart';
import 'package:sshub/features/ssh/presentation/widgets/color_picker.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class ServerDialog extends StatefulWidget {
  final SshServer? server;
  const ServerDialog({super.key, this.server});

  // Opens the form as a bottom sheet; returns the saved server or null.
  static Future<SshServer?> show(BuildContext context, {SshServer? server}) {
    return showModalBottomSheet<SshServer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ServerDialog(server: server),
    );
  }

  @override
  State<ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<ServerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.server?.label ?? "");
  late final _host = TextEditingController(text: widget.server?.host ?? "");
  late final _port = TextEditingController(
    text: widget.server?.port.toString() ?? "22",
  );
  late final _username = TextEditingController(
    text: widget.server?.username ?? "",
  );
  late final _description = TextEditingController(
    text: widget.server?.description ?? "",
  );
  final TextEditingController _password = TextEditingController();
  final TextEditingController _privateKey = TextEditingController();
  final TextEditingController _keyPassphrase = TextEditingController();
  late int? _color = widget.server?.colorValue;
  late AuthType _authType = widget.server?.authType ?? AuthType.password;

  bool get _isEditing => widget.server != null;
  // Quiet until the first failed save, then validate live as the user types.
  AutovalidateMode _autovalidateMode = .disabled;

  @override
  void dispose() {
    _label.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _privateKey.dispose();
    _keyPassphrase.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = .onUserInteraction);
      return;
    }
    // Secrets pass through untouched; a blank field on edit keeps the stored
    // value. The unused type keeps its secret too, so toggling does not wipe it.
    final isPassword = _authType == AuthType.password;
    final password = isPassword
        ? _keptSecret(_password, widget.server?.password)
        : (widget.server?.password ?? '');
    final keepingKey = _isEditing && _privateKey.text.isEmpty;
    final privateKey = isPassword
        ? (widget.server?.privateKey ?? '')
        : _keptSecret(_privateKey, widget.server?.privateKey);
    final passphrase = isPassword
        ? (widget.server?.passphrase ?? '')
        : (keepingKey && _keyPassphrase.text.isEmpty
              ? (widget.server?.passphrase ?? '')
              : _keyPassphrase.text);
    final server = SshServer(
      id: widget.server?.id ?? const Uuid().v7(),
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      authType: _authType,
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
      description: _description.text.trim(),
      colorValue: _color,
      lastConnectedAt: widget.server?.lastConnectedAt,
    );
    Navigator.pop(context, server);
  }

  // On edit, a blank secret field means "keep what's stored".
  String _keptSecret(TextEditingController controller, String? existing) =>
      _isEditing && controller.text.isEmpty
      ? (existing ?? '')
      : controller.text;

  Future<void> _importKeyFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null || !mounted) return;
    setState(() => _privateKey.text = utf8.decode(bytes));
  }

  Future<bool> _revealPassword() async {
    final locked = context
        .read<SettingsCubit>()
        .state
        .settings
        .lockPasswordReveal;
    final ok = await context.confirmReveal(
      locked: locked,
      reason: "Reveal saved server password",
    );
    final password = widget.server?.password ?? '';
    if (!ok || !mounted || password.isEmpty) return false;
    _password.text = password;
    return true;
  }

  // A stored secret exists only when editing a server that already has one.
  bool _hasStored(String? secret) => _isEditing && (secret ?? '').isNotEmpty;

  Widget _keyFields(ColorScheme scheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Private Key",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _importKeyFile,
              icon: const Icon(LucideIcons.fileUp, size: 18),
              label: const Text("Import"),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _privateKey,
          minLines: 3,
          maxLines: 6,
          style: const TextStyle(fontFamily: "monospace", fontSize: 12),
          decoration: InputDecoration(
            hintText: _hasStored(widget.server?.privateKey)
                ? "Leave blank to keep current key"
                : "-----BEGIN OPENSSH PRIVATE KEY-----",
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (v) {
            if (_hasStored(widget.server?.privateKey)) return null;
            return (v == null || v.trim().isEmpty)
                ? "Private key is required"
                : null;
          },
        ),
        const SizedBox(height: 12),
        DialogField(
          controller: _keyPassphrase,
          name: "Key Passphrase",
          icon: LucideIcons.asterisk,
          obscureText: true,
          required: false,
          textInputAction: .done,
          onSubmitted: (_) => _onSave(),
          hint: "Only if the key is encrypted",
        ),
      ],
    );
  }

  Widget _fields() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          icon: LucideIcons.info,
          title: "General Information",
        ),
        const SizedBox(height: 16),
        DialogField(
          controller: _label,
          name: "Server Label",
          hint: "e.g. Production API Server",
          icon: LucideIcons.tag,
          autofocus: !_isEditing,
        ),
        const SizedBox(height: 12),
        DialogField(
          controller: _description,
          name: "Description",
          hint: "Optional notes about this server",
          icon: LucideIcons.fileText,
          required: false,
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          icon: LucideIcons.network,
          title: "Connection Details",
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DialogField(
                controller: _host,
                name: "Host / IP",
                hint: "192.168.1.100",
                icon: LucideIcons.server,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DialogField(
                controller: _port,
                name: "Port",
                keyboardType: .number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final port = int.tryParse(v ?? "");
                  if (port == null || port < 1 || port > 65535) {
                    return "Error";
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DialogField(
          controller: _username,
          name: "SSH Username",
          hint: "root",
          icon: LucideIcons.circleUser,
        ),
        const SizedBox(height: 16),
        AuthTypeSelector(
          value: _authType,
          onChanged: (type) => setState(() => _authType = type),
        ),
        const SizedBox(height: 12),
        if (_authType == AuthType.password)
          DialogField(
            controller: _password,
            name: "SSH Password",
            icon: LucideIcons.keyRound,
            obscureText: true,
            textInputAction: .done,
            onSubmitted: (_) => _onSave(),
            required: !_hasStored(widget.server?.password),
            hint: _isEditing ? "Leave blank to keep current" : "••••••••",
            onReveal: _isEditing ? _revealPassword : null,
          )
        else
          _keyFields(scheme),
        const SizedBox(height: 24),
        const SectionHeader(icon: LucideIcons.palette, title: "Appearance"),
        const SizedBox(height: 8),
        ColorPicker(
          selected: _color,
          onSelected: (value) => setState(() => _color = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AppFormSheet(
    icon: _isEditing ? LucideIcons.notebookPen : LucideIcons.copyPlus,
    title: _isEditing ? "Edit Server" : "Add New Server",
    subtitle: _isEditing
        ? "Update your connection details"
        : "Configure a new remote connection",
    confirmLabel: _isEditing ? "Update Connection" : "Save Connection",
    onConfirm: _onSave,
    body: Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: _fields(),
    ),
  );
}
