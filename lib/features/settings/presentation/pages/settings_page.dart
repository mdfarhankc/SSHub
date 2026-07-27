import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/pages/settings_detail_page.dart';
import 'package:sshub/features/settings/presentation/widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const route = "/settings";

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Two panes once there is room for a list beside the detail.
  static const _twoPaneWidth = 840.0;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final sections = buildSettingsSections();
    if (_selected >= sections.length) _selected = 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _twoPaneWidth) {
              return _SectionList(
                sections: sections,
                onTap: (i) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsDetailPage(section: sections[i]),
                  ),
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 320,
                  child: _SectionList(
                    sections: sections,
                    selected: _selected,
                    onTap: (i) => setState(() => _selected = i),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  // Scoped to reduceMotion so typing in a detail field does not
                  // rebuild the whole page and steal focus from the input.
                  child: BlocSelector<SettingsCubit, SettingsState, bool>(
                    selector: (state) => state.settings.reduceMotion,
                    builder: (context, reduceMotion) => AnimatedSwitcher(
                      duration: Duration(milliseconds: reduceMotion ? 0 : 180),
                      child: _DetailPane(
                        key: ValueKey(sections[_selected].title),
                        section: sections[_selected],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final List<SettingsSection> sections;
  final int? selected;
  final ValueChanged<int> onTap;

  const _SectionList({
    required this.sections,
    required this.onTap,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final twoPane = selected != null;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: twoPane ? 8 : 0, vertical: 8),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final section = sections[i];
        final isSelected = selected == i;
        final base = section.destructive ? scheme.error : null;
        final accent = isSelected ? scheme.primary : base;
        return ListTile(
          shape: twoPane
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              : null,
          selected: isSelected,
          selectedTileColor: scheme.primary.withValues(alpha: 0.10),
          leading: Icon(section.icon, color: accent),
          title: Text(
            section.title,
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
          subtitle: Text(section.subtitle),
          trailing: twoPane
              ? null
              : const Icon(LucideIcons.chevronRight, size: 20),
          onTap: () => onTap(i),
        );
      },
    );
  }
}

class _DetailPane extends StatelessWidget {
  final SettingsSection section;
  const _DetailPane({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 48, 4, 32),
                  child: Text(
                    section.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                section.body(context),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
