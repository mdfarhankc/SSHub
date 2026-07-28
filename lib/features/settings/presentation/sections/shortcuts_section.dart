import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_divider.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_group.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_row.dart';
import 'package:sshub/features/settings/presentation/widgets/shortcut_recorder_dialog.dart';

class ShortcutsSection extends StatelessWidget {
  const ShortcutsSection({super.key});

  Future<void> _record(
    BuildContext context,
    ShortcutDef def,
    Map<String, String> overrides,
  ) async {
    final binding = await ShortcutRecorderDialog.show(context, def);
    if (binding == null || !context.mounted) return;
    final conflict = conflictingAction(def.action, binding, overrides);
    if (conflict != null) {
      showAppSnackBar(
        context,
        '${binding.display} is already used by "${shortcutDef(conflict).label}"',
        success: false,
      );
      return;
    }
    context.read<SettingsCubit>().updateShortcut(def.action, binding);
  }

  @override
  Widget build(BuildContext context) {
    // Group the catalog by category, preserving its declared order.
    final categories = <String, List<ShortcutDef>>{};
    for (final def in kShortcutDefs) {
      categories.putIfAbsent(def.category, () => []).add(def);
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) =>
          a.settings.shortcutOverrides != b.settings.shortcutOverrides,
      builder: (context, state) {
        final overrides = state.settings.shortcutOverrides;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: overrides.isEmpty
                    ? null
                    : () => context.read<SettingsCubit>().resetShortcuts(),
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text("Reset all"),
              ),
            ),
            const SizedBox(height: 4),
            for (final entry in categories.entries) ...[
              SettingsGroup(
                label: entry.key,
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const SettingsDivider(),
                    _ShortcutRow(
                      def: entry.value[i],
                      overrides: overrides,
                      onRecord: () =>
                          _record(context, entry.value[i], overrides),
                      onReset: () => context
                          .read<SettingsCubit>()
                          .updateShortcut(entry.value[i].action, null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final ShortcutDef def;
  final Map<String, String> overrides;
  final VoidCallback onRecord;
  final VoidCallback onReset;
  const _ShortcutRow({
    required this.def,
    required this.overrides,
    required this.onRecord,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final overridden = overrides.containsKey(def.action.name);
    return SettingsRow(
      title: def.label,
      keepInline: true,
      control: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (overridden)
            IconButton(
              tooltip: "Reset to default",
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              onPressed: onReset,
            ),
          OutlinedButton(
            onPressed: onRecord,
            child: Text(bindingFor(def.action, overrides).display),
          ),
        ],
      ),
    );
  }
}
