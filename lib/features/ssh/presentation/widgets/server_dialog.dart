import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/widgets/color_picker.dart';
import 'package:sshub/features/ssh/presentation/widgets/dialog_field.dart';
import 'package:uuid/uuid.dart';

class ServerDialog extends StatefulWidget {
  final SshServer? server;
  const ServerDialog({super.key, this.server});

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
    final server = SshServer(
      id: widget.server?.id ?? const Uuid().v7(),
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      description: _description.text.trim(),
      colorValue: _color,
    );
    // Secrets pass through untouched: never trim, never log.
    final password = _isEditing && _password.text.isEmpty
        ? null
        : _password.text;
    Navigator.pop(context, (server: server, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? "Edit Server" : "Add Server"),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: .min,
              spacing: 12,
              children: [
                DialogField(
                  controller: _label,
                  name: "Label",
                  hint: "Production server",
                  icon: Icons.label_outline,
                  autofocus: true,
                ),
                DialogField(
                  controller: _description,
                  name: "Description",
                  hint: "What this server is for",
                  icon: Icons.notes_outlined,
                  required: false,
                ),
                Row(
                  spacing: 12,
                  // Top-align so an error under Port doesn't drag Host down.
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DialogField(
                        controller: _host,
                        name: "Host",
                        hint: "192.168.1.10",
                        icon: Icons.dns_outlined,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: DialogField(
                        controller: _port,
                        name: "Port",
                        keyboardType: .number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          final port = int.tryParse(v ?? "");
                          if (port == null || port < 1 || port > 65535) {
                            return "1-65535";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                DialogField(
                  controller: _username,
                  name: "Username",
                  icon: Icons.person_outline,
                ),
                DialogField(
                  controller: _password,
                  name: "Password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: .done,
                  onSubmitted: (_) => _onSave(),
                  required: !_isEditing,
                  hint: _isEditing ? "Leave blank to keep current" : null,
                ),
                ColorPicker(
                  selected: _color,
                  onSelected: (value) => setState(() => _color = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(onPressed: _onSave, child: const Text("Save")),
      ],
    );
  }
}
