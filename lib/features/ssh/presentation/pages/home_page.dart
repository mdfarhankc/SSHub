import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/auth/reveal_guard.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/shortcuts/shortcut_actions.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/command_palette.dart';
import 'package:sshub/core/widgets/page_title.dart';
import 'package:sshub/features/help/presentation/pages/help_page.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/cubit/hidden_servers_cubit.dart';
import 'package:sshub/features/ssh/presentation/cubit/workspace_sessions_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/workspace_page.dart';
import 'package:sshub/features/ssh/presentation/widgets/home_header.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_card.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';
import 'package:sshub/features/workflows/presentation/pages/workflows_page.dart';

// 180 carries deliberate slack, so the card only needs to grow once its text
// would outgrow it, which is well above the usual scales.
SliverGridDelegateWithMaxCrossAxisExtent _gridDelegateFor(
  BuildContext context,
) => SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 450,
  mainAxisSpacing: 16,
  crossAxisSpacing: 16,
  mainAxisExtent: math.max(
    180,
    52 + MediaQuery.textScalerOf(context).scale(66),
  ),
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const route = "/home";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = "";
  final _searchFocus = FocusNode();
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    // Probe reachability once on launch, but only after the entry transition
    // has settled; kicking it off during the fade stutters the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) _checkReachability(context);
      });
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<SshServer> _filter(List<SshServer> servers, String? tag) {
    final q = _query.trim().toLowerCase();
    return servers.where((s) {
      if (tag != null && !s.tags.contains(tag)) return false;
      if (q.isEmpty) return true;
      return s.label.toLowerCase().contains(q) ||
          s.host.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.tags.any((t) => t.contains(q));
    }).toList();
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.pushNamed(context, SettingsPage.route);
    if (context.mounted) {
      context.read<ServerListBloc>().add(ServerListLoaded());
    }
  }

  Future<void> _addServer(BuildContext context) async {
    final result = await ServerDialog.show(context);
    if (result != null && context.mounted) {
      context.read<ServerListBloc>().add(ServerAdded(result));
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ServerListBloc>();
    if (bloc.state.servers.isEmpty) return;
    bloc.add(ServerReachabilityRequested());
    await bloc.stream.firstWhere(
      (s) =>
          s.reachability.length >= s.servers.length &&
          !s.reachability.values.contains(Reachability.checking),
    );
  }

  void _checkReachability(BuildContext context) =>
      context.read<ServerListBloc>().add(ServerReachabilityRequested());

  void _focusSearch() => _searchFocus.requestFocus();

  // Authenticates, then reveals servers behind a locked tag for this session.
  Future<void> _revealHidden(BuildContext context) async {
    final ok = await context.confirmReveal(
      locked: true,
      reason: "Show hidden servers",
    );
    if (ok && context.mounted) context.read<HiddenServersCubit>().reveal();
  }

  // The rebindable actions and their handlers, shared by the shortcut map and
  // the command palette so neither drifts from the other.
  Map<ShortcutAction, VoidCallback> _actionHandlers(BuildContext context) => {
    ShortcutAction.commandPalette: () => _openPalette(context),
    ShortcutAction.addServer: () => _addServer(context),
    ShortcutAction.focusSearch: _focusSearch,
    ShortcutAction.openSnippets: () =>
        Navigator.pushNamed(context, SnippetsPage.route),
    ShortcutAction.openSettings: () => _openSettings(context),
    ShortcutAction.refreshServers: () => _checkReachability(context),
    ShortcutAction.toggleTheme: () =>
        context.read<SettingsCubit>().toggleThemeMode(),
  };

  Map<ShortcutActivator, VoidCallback> _shortcutBindings(
    BuildContext context,
    Map<String, String> overrides,
  ) => {
    ...buildShortcuts(_actionHandlers(context), overrides),
    // Fixed function keys stay out of the customisable set.
    const SingleActivator(LogicalKeyboardKey.f1): () =>
        Navigator.pushNamed(context, HelpPage.route),
    const SingleActivator(LogicalKeyboardKey.f5): () =>
        _checkReachability(context),
  };

  // Lists the rebindable commands plus a connect and browse entry for every
  // server, so anything on Home is reachable by typing.
  void _openPalette(BuildContext context) {
    final overrides =
        context.read<SettingsCubit>().state.settings.shortcutOverrides;
    final servers = context.read<ServerListBloc>().state.servers;
    final sessions = context.read<WorkspaceSessionsCubit>();

    final commands = <PaletteCommand>[
      for (final entry in _actionHandlers(context).entries)
        if (entry.key != ShortcutAction.commandPalette)
          PaletteCommand(
            label: shortcutDef(entry.key).label,
            hint: shortcutDef(entry.key).category,
            trailing: bindingFor(entry.key, overrides).display,
            icon: _paletteIcon(entry.key),
            onRun: entry.value,
          ),
      for (final s in servers) ...[
        PaletteCommand(
          label: "Connect to ${s.label}",
          hint: "${s.username}@${s.host}",
          icon: LucideIcons.terminal,
          onRun: () {
            sessions.openTerminal(s);
            Navigator.pushNamed(context, WorkspacePage.route);
          },
        ),
        PaletteCommand(
          label: "Browse files on ${s.label}",
          hint: "${s.username}@${s.host}",
          icon: LucideIcons.folderOpen,
          onRun: () {
            sessions.openFiles(s);
            Navigator.pushNamed(context, WorkspacePage.route);
          },
        ),
      ],
    ];
    showCommandPalette(context, commands: commands);
  }

  static IconData _paletteIcon(ShortcutAction action) => switch (action) {
    ShortcutAction.addServer => LucideIcons.plus,
    ShortcutAction.focusSearch => LucideIcons.search,
    ShortcutAction.openSnippets => LucideIcons.zap,
    ShortcutAction.openSettings => LucideIcons.settings,
    ShortcutAction.refreshServers => LucideIcons.refreshCw,
    ShortcutAction.toggleTheme => LucideIcons.moon,
    _ => LucideIcons.chevronRight,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mod = shortcutModifierLabel;
    final overrides = context.select<SettingsCubit, Map<String, String>>(
      (c) => c.state.settings.shortcutOverrides,
    );
    // Locked tags only hide servers while app lock is on, so a disabled lock
    // (or a backup restored onto a device without one) reveals everything.
    final lockedTags = context.select<SettingsCubit, Set<String>>(
      (c) => c.state.settings.appLockEnabled
          ? c.state.settings.lockedTags
          : const {},
    );
    final hiddenServers = context.watch<HiddenServersCubit>();
    final revealed = hiddenServers.state;

    return Scaffold(
      body: CallbackShortcuts(
        bindings: _shortcutBindings(context, overrides),
        child: Focus(
          autofocus: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.maxContentWidth,
              ),
              child: BlocConsumer<ServerListBloc, ServerListState>(
                listenWhen: (previous, current) => current.errorMessage != null,
                listener: (context, state) {
                  showAppSnackBar(context, state.errorMessage!, success: false);
                },
                builder: (context, state) {
                  // Servers behind a locked tag stay out of the grid, search and
                  // tag chips until the user authenticates to reveal them.
                  final lockedCount = lockedTags.isEmpty
                      ? 0
                      : state.servers
                            .where((s) => s.tags.any(lockedTags.contains))
                            .length;
                  final visible = revealed || lockedCount == 0
                      ? state.servers
                      : [
                          for (final s in state.servers)
                            if (!s.tags.any(lockedTags.contains)) s,
                        ];
                  final allTags = <String>{
                    for (final s in visible) ...s.tags,
                  }.toList()..sort();
                  // Drop a selection whose tag no longer exists on any server.
                  final activeTag =
                      (_tagFilter != null && !allTags.contains(_tagFilter))
                      ? null
                      : _tagFilter;
                  final servers = _filter(visible, activeTag);
                  final isLoading =
                      state.status == ServerListStatus.loading ||
                      state.status == ServerListStatus.initial;

                  const hPad = 16.0;
                  final isMobile = context.isMobile;
                  final showStats =
                      !isLoading &&
                      visible.isNotEmpty &&
                      _query.isEmpty &&
                      activeTag == null;
                  final isChecking = state.reachability.values.contains(
                    Reachability.checking,
                  );

                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: CustomScrollView(
                      scrollBehavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          expandedHeight: 132,
                          toolbarHeight: 64,
                          backgroundColor: scheme.surface,
                          surfaceTintColor: Colors.transparent,
                          actions: [
                            if (!Platform.isAndroid && !Platform.isIOS)
                              IconButton(
                                onPressed: isChecking
                                    ? null
                                    : () => _checkReachability(context),
                                icon: isChecking
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      )
                                    : const Icon(LucideIcons.refreshCw),
                                color: scheme.onSurfaceVariant,
                                tooltip: "Refresh status ($mod+R)",
                              ),
                            if (!Platform.isAndroid && !Platform.isIOS)
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  HelpPage.route,
                                ),
                                icon: const Icon(LucideIcons.circleHelp),
                                color: scheme.onSurfaceVariant,
                                tooltip: "Help (F1)",
                              ),
                            IconButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                SnippetsPage.route,
                              ),
                              icon: const Icon(LucideIcons.zap),
                              color: scheme.onSurfaceVariant,
                              tooltip: "Snippets ($mod+E)",
                            ),
                            IconButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                WorkflowsPage.route,
                              ),
                              icon: const Icon(LucideIcons.workflow),
                              color: scheme.onSurfaceVariant,
                              tooltip: "Workflows",
                            ),
                            IconButton(
                              onPressed: () => _openSettings(context),
                              icon: const Icon(LucideIcons.settings),
                              color: scheme.onSurfaceVariant,
                              tooltip: "Settings ($mod+,)",
                            ),
                            const SizedBox(width: 8),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            titlePadding: const EdgeInsetsDirectional.only(
                              start: hPad,
                              bottom: 16,
                            ),
                            expandedTitleScale: 1.6,
                            title: const PageTitle("SSHub"),
                            background: showStats
                                ? Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: hPad,
                                        bottom: 24,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _HeaderStat(
                                            icon: LucideIcons.server,
                                            value: visible.length.toString(),
                                            label: "Servers",
                                            compact: isMobile,
                                          ),
                                          SizedBox(width: isMobile ? 14 : 20),
                                          _HeaderStat(
                                            icon: LucideIcons.history,
                                            value: visible
                                                .where(
                                                  (s) =>
                                                      s.lastConnectedAt != null,
                                                )
                                                .length
                                                .toString(),
                                            label: "Connected",
                                            compact: isMobile,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _ToolbarHeaderDelegate(
                            hPad: hPad,
                            height: _ToolbarHeaderDelegate.heightFor(context),
                            child: HomeHeader(
                              searchFocusNode: _searchFocus,
                              onSearchChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                        ),
                        if (!isLoading && allTags.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _TagFilterBar(
                              tags: allTags,
                              selected: activeTag,
                              hPad: hPad,
                              onSelected: (value) =>
                                  setState(() => _tagFilter = value),
                            ),
                          ),
                        if (!isLoading &&
                            lockedCount > 0 &&
                            hiddenServers.canEnforce)
                          SliverToBoxAdapter(
                            child: _HiddenServersBar(
                              hPad: hPad,
                              revealed: revealed,
                              count: lockedCount,
                              onReveal: () => _revealHidden(context),
                              onHide: () =>
                                  context.read<HiddenServersCubit>().hide(),
                            ),
                          ),
                        if (isLoading)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                            sliver: SliverGrid(
                              gridDelegate: _gridDelegateFor(context),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => const _SkeletonCard(),
                                childCount: 6,
                              ),
                            ),
                          )
                        else if (state.status == ServerListStatus.failure)
                          const SliverFillRemaining(
                            child: Center(
                              child: Text("Failed to load servers"),
                            ),
                          )
                        else if (servers.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              searching:
                                  _query.trim().isNotEmpty || activeTag != null,
                              hidden: visible.isEmpty && lockedCount > 0,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                            sliver: SliverGrid(
                              gridDelegate: _gridDelegateFor(context),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => ServerCard(
                                  server: servers[index],
                                  reachability:
                                      state.reachability[servers[index].id] ??
                                      Reachability.unknown,
                                ),
                                childCount: servers.length,
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double hPad;
  final double height;
  final Widget child;
  const _ToolbarHeaderDelegate({
    required this.hPad,
    required this.height,
    required this.child,
  });

  // The search field and the button are sized by their text, so a pinned
  // header of a fixed height would clip them as the text scale rises.
  static double heightFor(BuildContext context) =>
      16 + MediaQuery.textScalerOf(context).scale(56);

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      alignment: Alignment.center,
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ToolbarHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.hPad != hPad ||
      oldDelegate.height != height;
}

// Shown when any server carries a locked tag: unlock to reveal them, or hide
// them again once revealed.
class _HiddenServersBar extends StatelessWidget {
  final double hPad;
  final bool revealed;
  final int count;
  final VoidCallback onReveal;
  final VoidCallback onHide;
  const _HiddenServersBar({
    required this.hPad,
    required this.revealed,
    required this.count,
    required this.onReveal,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 4),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: revealed ? onHide : onReveal,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  revealed ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    revealed
                        ? "Showing hidden servers"
                        : "$count ${count == 1 ? 'server' : 'servers'} hidden",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  revealed ? "Hide" : "Show",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  revealed ? LucideIcons.lock : LucideIcons.fingerprint,
                  size: 14,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A horizontally scrolling row of tag filters above the server grid. Tapping a
// selected chip clears the filter, so there is no separate "clear" control.
class _TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String? selected;
  final double hPad;
  final ValueChanged<String?> onSelected;

  const _TagFilterBar({
    required this.tags,
    required this.selected,
    required this.hPad,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? value) {
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Center(
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(isSelected ? null : value),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        children: [chip("All", null), for (final tag in tags) chip(tag, tag)],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  // Every server is behind a locked tag, so there is nothing to show until the
  // user unlocks them from the bar above.
  final bool hidden;
  const _EmptyState({required this.searching, this.hidden = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = hidden
        ? LucideIcons.eyeOff
        : (searching ? LucideIcons.searchX : LucideIcons.server);
    final title = hidden
        ? "Servers are hidden"
        : (searching ? "No servers found" : "No servers added yet");
    final body = hidden
        ? "Unlock them from the bar above to view them."
        : (searching
              ? "We couldn't find any servers matching your search query. Try something else?"
              : "Start by adding your first SSH server to manage it from SSHub.");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!searching && !hidden) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ServerDialog.show(context).then((result) {
                    if (result != null && context.mounted) {
                      context.read<ServerListBloc>().add(ServerAdded(result));
                    }
                  });
                },
                icon: const Icon(LucideIcons.plus),
                label: const Text("Add your first server"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: Tween(begin: 0.04, end: 0.12).animate(_controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                block(40, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(120, 14),
                      const SizedBox(height: 8),
                      block(80, 12),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [block(90, 18), block(18, 18)],
            ),
          ],
        ),
      ),
    );
  }
}
