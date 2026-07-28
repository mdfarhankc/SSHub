// Snippet values can carry placeholders like {{host}} or {{prompt:Log path}}.
// Context tokens resolve from the active session; prompt tokens ask the user.
final _placeholder = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

const _promptPrefix = 'prompt:';

class SnippetContext {
  final String? host;
  final String? user;
  final int? port;
  const SnippetContext({this.host, this.user, this.port});
}

bool snippetHasPlaceholders(String value) => _placeholder.hasMatch(value);

// The distinct labels a snippet asks the user for, in first-seen order.
List<String> snippetPrompts(String value) {
  final labels = <String>[];
  for (final match in _placeholder.allMatches(value)) {
    final token = match.group(1)!.trim();
    if (token.startsWith(_promptPrefix)) {
      final label = token.substring(_promptPrefix.length).trim();
      if (label.isNotEmpty && !labels.contains(label)) labels.add(label);
    }
  }
  return labels;
}

// Fills in context and prompt tokens. Unknown tokens are left untouched so a
// typo shows up in the output rather than silently vanishing.
String resolveSnippet(
  String value, {
  SnippetContext context = const SnippetContext(),
  Map<String, String> answers = const {},
}) {
  return value.replaceAllMapped(_placeholder, (match) {
    final token = match.group(1)!.trim();
    switch (token) {
      case 'host':
        return context.host ?? match.group(0)!;
      case 'user':
        return context.user ?? match.group(0)!;
      case 'port':
        return context.port?.toString() ?? match.group(0)!;
    }
    if (token.startsWith(_promptPrefix)) {
      final label = token.substring(_promptPrefix.length).trim();
      return answers[label] ?? match.group(0)!;
    }
    return match.group(0)!;
  });
}
