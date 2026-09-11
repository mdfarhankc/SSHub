import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:sshub/core/shortcuts/app_shortcuts.dart';

// A rebindable command. Names are stable and used as the override storage key,
// so do not rename them without a migration.
enum ShortcutAction {
  addServer,
  focusSearch,
  openSnippets,
  openSettings,
  refreshServers,
  toggleTheme,
  newTab,
  closeTab,
  find,
  snippets,
  workflows,
  copySelection,
  pasteClipboard,
  selectAll,
}

// Conflict scope: two actions in the same group must not share a binding, but
// the same combo may mean different things on Home vs in a session.
enum ShortcutGroup { home, workspace }

// The primary modifier is Ctrl on most platforms and Cmd on Apple, so a binding
// stores it as [primary] rather than a concrete modifier.
class KeyBinding {
  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool alt;

  const KeyBinding(
    this.key, {
    this.primary = true,
    this.shift = false,
    this.alt = false,
  });

  SingleActivator get activator => SingleActivator(
    key,
    control: primary && !isApplePlatform,
    meta: primary && isApplePlatform,
    shift: shift,
    alt: alt,
  );

  bool matches(KeyEvent event) =>
      event is KeyDownEvent &&
      activator.accepts(event, HardwareKeyboard.instance);

  String get display => [
    if (primary) shortcutModifierLabel,
    if (shift) "Shift",
    if (alt) (isApplePlatform ? "Opt" : "Alt"),
    _keyName(key),
  ].join("+");

  String serialize() =>
      "${primary ? 1 : 0}${shift ? 1 : 0}${alt ? 1 : 0}:${key.keyId}";

  static KeyBinding? tryParse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(":");
    if (parts.length != 2 || parts[0].length != 3) return null;
    final keyId = int.tryParse(parts[1]);
    if (keyId == null) return null;
    return KeyBinding(
      LogicalKeyboardKey(keyId),
      primary: parts[0][0] == "1",
      shift: parts[0][1] == "1",
      alt: parts[0][2] == "1",
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeyBinding &&
      other.key == key &&
      other.primary == primary &&
      other.shift == shift &&
      other.alt == alt;

  @override
  int get hashCode => Object.hash(key, primary, shift, alt);
}

String _keyName(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.comma) return ",";
  if (key == LogicalKeyboardKey.period) return ".";
  if (key == LogicalKeyboardKey.slash) return "/";
  if (key == LogicalKeyboardKey.space) return "Space";
  if (key == LogicalKeyboardKey.tab) return "Tab";
  final label = key.keyLabel;
  if (label.isNotEmpty) return label.toUpperCase();
  return key.debugName ?? "?";
}

class ShortcutDef {
  final ShortcutAction action;
  final String label;
  final String category;
  final ShortcutGroup group;
  final KeyBinding defaultBinding;

  const ShortcutDef({
    required this.action,
    required this.label,
    required this.category,
    required this.group,
    required this.defaultBinding,
  });
}

const kShortcutDefs = <ShortcutDef>[
  ShortcutDef(
    action: ShortcutAction.addServer,
    label: "Add a server",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyN),
  ),
  ShortcutDef(
    action: ShortcutAction.focusSearch,
    label: "Search servers",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyF),
  ),
  ShortcutDef(
    action: ShortcutAction.openSnippets,
    label: "Open snippets",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyE),
  ),
  ShortcutDef(
    action: ShortcutAction.openSettings,
    label: "Open settings",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.comma),
  ),
  ShortcutDef(
    action: ShortcutAction.refreshServers,
    label: "Refresh server status",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyR),
  ),
  ShortcutDef(
    action: ShortcutAction.toggleTheme,
    label: "Toggle light and dark",
    category: "General",
    group: ShortcutGroup.home,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyD, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.newTab,
    label: "New session tab",
    category: "Tabs",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyT, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.closeTab,
    label: "Close tab",
    category: "Tabs",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyW, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.find,
    label: "Find in terminal",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyF),
  ),
  ShortcutDef(
    action: ShortcutAction.snippets,
    label: "Open snippet picker",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyS, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.workflows,
    label: "Open workflow picker",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyR, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.copySelection,
    label: "Copy selection",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyC, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.pasteClipboard,
    label: "Paste",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyV, shift: true),
  ),
  ShortcutDef(
    action: ShortcutAction.selectAll,
    label: "Select all",
    category: "Terminal",
    group: ShortcutGroup.workspace,
    defaultBinding: KeyBinding(LogicalKeyboardKey.keyA, shift: true),
  ),
];

ShortcutDef shortcutDef(ShortcutAction action) =>
    kShortcutDefs.firstWhere((d) => d.action == action);

// The active binding for an action: the user override if present, else default.
KeyBinding bindingFor(ShortcutAction action, Map<String, String> overrides) =>
    KeyBinding.tryParse(overrides[action.name]) ??
    shortcutDef(action).defaultBinding;

// Builds a CallbackShortcuts map, resolving each handler's action to its
// current binding.
Map<ShortcutActivator, VoidCallback> buildShortcuts(
  Map<ShortcutAction, VoidCallback> handlers,
  Map<String, String> overrides,
) => {
  for (final entry in handlers.entries)
    bindingFor(entry.key, overrides).activator: entry.value,
};

// The first action in [among] whose binding matches the raw event, for the
// terminal's own key handling.
ShortcutAction? matchShortcut(
  KeyEvent event,
  Map<String, String> overrides,
  Set<ShortcutAction> among,
) {
  if (event is! KeyDownEvent) return null;
  for (final action in among) {
    if (bindingFor(action, overrides).matches(event)) return action;
  }
  return null;
}

// The action already using [binding] within [group], if any, ignoring [self].
ShortcutAction? conflictingAction(
  ShortcutAction self,
  KeyBinding binding,
  Map<String, String> overrides,
) {
  final group = shortcutDef(self).group;
  for (final def in kShortcutDefs) {
    if (def.action == self || def.group != group) continue;
    if (bindingFor(def.action, overrides) == binding) return def.action;
  }
  return null;
}
