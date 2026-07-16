import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/widgets/segmented_selector.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';

class AuthTypeSelector extends StatelessWidget {
  final AuthType value;
  final ValueChanged<AuthType> onChanged;
  const AuthTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SegmentedSelector<AuthType>(
    value: value,
    onChanged: onChanged,
    options: const [
      (AuthType.password, LucideIcons.keyRound, "Password"),
      (AuthType.key, LucideIcons.key, "SSH Key"),
    ],
  );
}
