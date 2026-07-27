import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_group.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';

class ConnectionsSection extends StatefulWidget {
  const ConnectionsSection({super.key});

  @override
  State<ConnectionsSection> createState() => _ConnectionsSectionState();
}

class _ConnectionsSectionState extends State<ConnectionsSection> {
  late final TextEditingController _port;
  late final TextEditingController _username;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state.settings;
    _port = TextEditingController(text: settings.defaultPort.toString());
    _username = TextEditingController(text: settings.defaultUsername);
  }

  @override
  void dispose() {
    _port.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return SettingsGroup(
      description: "Values prefilled when you add a new server.",
      children: [
        SettingsRow(
          title: "Default port",
          subtitle: "Usually 22.",
          control: SizedBox(
            width: 100,
            child: TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(isDense: true),
              onChanged: (v) {
                final port = int.tryParse(v);
                if (port != null && port >= 1 && port <= 65535) {
                  cubit.updateDefaultPort(port);
                }
              },
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsRow(
          title: "Default username",
          subtitle: "Leave blank for none.",
          control: SizedBox(
            width: 180,
            child: TextField(
              controller: _username,
              decoration: const InputDecoration(isDense: true),
              onChanged: (v) => cubit.updateDefaultUsername(v.trim()),
            ),
          ),
        ),
      ],
    );
  }
}
