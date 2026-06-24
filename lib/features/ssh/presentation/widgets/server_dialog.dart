import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/widgets/color_picker.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class ServerDialog extends StatefulWidget {
  final SshServer? server;
  final bool sheet;
  const ServerDialog({super.key, this.server, this.sheet = false});

  // Presents the form as a bottom sheet on narrow screens and a centered
  // dialog otherwise, returning the saved server or null if cancelled.
  static Future<SshServer?> show(
    BuildContext context, {
    SshServer? server,
  }) {
    if (Responsive.isMobile(context)) {
      return showModalBottomSheet<SshServer>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ServerDialog(server: server, sheet: true),
      );
    }
    return showDialog<SshServer>(
      context: context,
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
  late int? _color = widget.server?.colorValue;

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
    _description.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = .onUserInteraction);
      return;
    }
    // Secrets pass through untouched: never trim, never log.
    // When editing with the field left blank, keep the existing password.
    final password = _isEditing && _password.text.isEmpty
        ? (widget.server?.password ?? '')
        : _password.text;
    final server = SshServer(
      id: widget.server?.id ?? const Uuid().v7(),
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      password: password,
      description: _description.text.trim(),
      colorValue: _color,
      lastConnectedAt: widget.server?.lastConnectedAt,
    );
    Navigator.pop(context, server);
  }

  Future<bool> _revealPassword() async {
    final auth = context.read<LocalAuthService>();
    final lock =
        context.read<SettingsCubit>().state.settings.lockPasswordReveal;
    if (lock) {
      final ok = await auth.authenticate("Reveal saved server password");
      if (!ok) return false;
    }
    final password = widget.server?.password ?? '';
    if (!mounted || password.isEmpty) return false;
    _password.text = password;
    return true;
  }

  Widget _fields() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.info_outlined,
          title: "General Information",
          color: scheme.primary,
        ),
        const SizedBox(height: 16),
        DialogField(
          controller: _label,
          name: "Server Label",
          hint: "e.g. Production API Server",
          icon: Icons.label_important_outlined,
          autofocus: !_isEditing,
        ),
        const SizedBox(height: 12),
        DialogField(
          controller: _description,
          name: "Description",
          hint: "Optional notes about this server",
          icon: Icons.description_outlined,
          required: false,
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.lan_outlined,
          title: "Connection Details",
          color: scheme.primary,
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
                icon: Icons.dns_outlined,
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
          icon: Icons.account_circle_outlined,
        ),
        const SizedBox(height: 12),
        DialogField(
          controller: _password,
          name: "SSH Password",
          icon: Icons.vpn_key_outlined,
          obscureText: true,
          textInputAction: .done,
          onSubmitted: (_) => _onSave(),
          required: !_isEditing,
          hint: _isEditing ? "Leave blank to keep current" : "••••••••",
          onReveal: _isEditing ? _revealPassword : null,
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.palette_outlined,
          title: "Appearance",
          color: scheme.primary,
        ),
        const SizedBox(height: 8),
        ColorPicker(
          selected: _color,
          onSelected: (value) => setState(() => _color = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.sheet ? _buildSheet(context) : _buildDialog(context);
  }

  Widget _buildSheet(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(child: _content(context)),
        ],
      ),
    );
  }

  Widget _buildDialog(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: _content(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEditing ? Icons.edit_note_rounded : Icons.add_to_photos_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? "Edit Server" : "Add New Server",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isEditing
                          ? "Update your connection details"
                          : "Configure a new remote connection",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: _fields(),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _onSave,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(_isEditing ? "Update Connection" : "Save Connection"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
