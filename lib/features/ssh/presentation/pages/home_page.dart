import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sshub/core/responsive/responsive.dart';
import 'package:sshub/core/shortcuts/app_shortcuts.dart';
import 'package:sshub/core/shortcuts/shortcuts_help_dialog.dart';
import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/core/widgets/app_snack_bar.dart';
import 'package:sshub/core/widgets/page_title.dart';
import 'package:sshub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sshub/features/settings/presentation/pages/settings_page.dart';
import 'package:sshub/features/snippets/presentation/pages/snippets_page.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/widgets/home_header.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_card.dart';
import 'package:sshub/features/ssh/presentation/widgets/server_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    // Servers are loaded before Home mounts, so probe them once on launch.
    _checkReachability(context);
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<SshServer> _filter(List<SshServer> servers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return servers;
    return servers
        .where(
          (s) =>
              s.label.toLowerCase().contains(q) ||
              s.host.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q),
        )
        .toList();
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

  Map<ShortcutActivator, VoidCallback> _shortcutBindings(
    BuildContext context,
  ) => {
    ...shortcutBinding(LogicalKeyboardKey.keyN, () => _addServer(context)),
    ...shortcutBinding(LogicalKeyboardKey.keyF, _focusSearch),
    ...shortcutBinding(
      LogicalKeyboardKey.keyE,
      () => Navigator.pushNamed(context, SnippetsPage.route),
    ),
    ...shortcutBinding(LogicalKeyboardKey.comma, () => _openSettings(context)),
    ...shortcutBinding(
      LogicalKeyboardKey.keyR,
      () => _checkReachability(context),
    ),
    ...shortcutBinding(
      LogicalKeyboardKey.keyD,
      () => context.read<SettingsCubit>().toggleThemeMode(),
      shift: true,
    ),
    const SingleActivator(LogicalKeyboardKey.f1): () =>
        ShortcutsHelpDialog.show(context),
    const SingleActivator(LogicalKeyboardKey.f5): () =>
        _checkReachability(context),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mod = shortcutModifierLabel;

    return Scaffold(
      body: CallbackShortcuts(
        bindings: _shortcutBindings(context),
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
                  final servers = _filter(state.servers);
                  final isLoading =
                      state.status == ServerListStatus.loading ||
                      state.status == ServerListStatus.initial;

                  const hPad = 16.0;
                  final isMobile = context.isMobile;
                  final showStats =
                      !isLoading && state.servers.isNotEmpty && _query.isEmpty;
                  final isChecking = state.reachability.values.contains(
                    Reachability.checking,
                  );

                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: CustomScrollView(
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
                                onPressed: () =>
                                    ShortcutsHelpDialog.show(context),
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
                                            value: state.servers.length
                                                .toString(),
                                            label: "Servers",
                                            compact: isMobile,
                                          ),
                                          SizedBox(width: isMobile ? 14 : 20),
                                          _HeaderStat(
                                            icon: LucideIcons.history,
                                            value: state.servers
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
                              searching: _query.trim().isNotEmpty,
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
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
              child: Icon(
                searching ? LucideIcons.searchX : LucideIcons.server,
                size: 64,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searching ? "No servers found" : "No servers added yet",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? "We couldn't find any servers matching your search query. Try something else?"
                  : "Start by adding your first SSH server to manage it from SSHub.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!searching) ...[
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
