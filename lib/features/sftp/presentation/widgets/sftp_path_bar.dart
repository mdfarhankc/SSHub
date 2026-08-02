import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sshub/core/theme/app_theme.dart';
import 'package:sshub/features/sftp/presentation/cubit/sftp_cubit.dart';

class SftpPathBar extends StatefulWidget {
  static const height = 45.0;

  final SftpState state;
  final SftpCubit cubit;
  const SftpPathBar({super.key, required this.state, required this.cubit});

  @override
  State<SftpPathBar> createState() => _SftpPathBarState();
}

class _SftpPathBarState extends State<SftpPathBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  bool _editing = false;
  double _fieldWidth = 0;

  String _currentParent = '/';
  String? _cachedDir;
  List<String> _cachedDirs = const [];
  List<String> _suggestions = const [];
  int _reqToken = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _editing) {
      setState(() => _editing = false);
      _portal.hide();
    }
  }

  void _startEditing() {
    _controller.text = widget.state.path;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _cachedDir = null;
    setState(() => _editing = true);
    _focus.requestFocus();
    _onChanged(_controller.text);
  }

  void _submit() {
    final value = _controller.text;
    setState(() => _editing = false);
    _portal.hide();
    widget.cubit.goToPath(value);
  }

  Future<void> _onChanged(String text) async {
    final slash = text.lastIndexOf('/');
    final parent = slash <= 0 ? '/' : text.substring(0, slash + 1);
    final partial = text.substring(slash + 1).toLowerCase();
    final dir = parent == '/' ? '/' : parent.substring(0, parent.length - 1);
    _currentParent = parent;
    await _ensureListed(dir);
    if (!mounted || !_editing) return;
    final matches = [
      for (final name in _cachedDirs)
        if (name.toLowerCase().startsWith(partial)) name,
    ];
    setState(() => _suggestions = matches.take(10).toList());
    if (_suggestions.isEmpty) {
      _portal.hide();
    } else if (!_portal.isShowing) {
      _portal.show();
    }
  }

  Future<void> _ensureListed(String dir) async {
    if (dir == _cachedDir) return;
    final token = ++_reqToken;
    final dirs = await widget.cubit.listFolder(dir);
    if (!mounted || token != _reqToken) return;
    _cachedDir = dir;
    _cachedDirs = [for (final d in dirs) d.name]..sort();
  }

  void _applySuggestion(String name) {
    final completed = '$_currentParent$name/';
    _controller.text = completed;
    _controller.selection = TextSelection.collapsed(offset: completed.length);
    _focus.requestFocus();
    _onChanged(completed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = widget.state;

    return Container(
      height: SftpPathBar.height,
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: "Up one folder",
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            onPressed: state.isRoot ? null : widget.cubit.goUp,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: OverlayPortal(
              controller: _portal,
              overlayChildBuilder: _buildSuggestions,
              child: CompositedTransformTarget(
                link: _link,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _fieldWidth = constraints.maxWidth;
                    return _editing
                        ? _field(theme, scheme)
                        : _display(theme, scheme, state.path);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _display(ThemeData theme, ColorScheme scheme, String path) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: _startEditing,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              path,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: AppTheme.mono,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(ThemeData theme, ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _focus.unfocus,
      },
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: true,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: AppTheme.mono),
        textInputAction: TextInputAction.go,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
        onChanged: _onChanged,
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: TextFieldTapRegion(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _fieldWidth,
            child: Material(
              elevation: 8,
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final name = _suggestions[index];
                    return InkWell(
                      onTap: () => _applySuggestion(name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.folder,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: AppTheme.mono,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
