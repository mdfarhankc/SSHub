// Snippet values can carry placeholders like {{host}} or {{prompt:Log path}}.
// Context tokens resolve from the active session; prompt tokens ask the user. A
// prompt can suggest values with {{prompt:branch|main,develop}}, shown as
// options the user can pick or override.
final _placeholder = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

const _promptPrefix = 'prompt:';

class SnippetContext {
  final String? host;
  final String? user;
  final int? port;
  const SnippetContext({this.host, this.user, this.port});
}

// A value the user is asked for, with any suggested options to choose from.
class SnippetPrompt {
  final String label;
  final List<String> options;
  const SnippetPrompt(this.label, {this.options = const []});
}

bool snippetHasPlaceholders(String value) => _placeholder.hasMatch(value);

// The label before a '|' names the prompt; anything after it is a comma list of
// suggested options.
({String label, List<String> options}) _parsePrompt(String spec) {
  final sep = spec.indexOf('|');
  if (sep == -1) return (label: spec.trim(), options: const []);
  final options = [
    for (final o in spec.substring(sep + 1).split(','))
      if (o.trim().isNotEmpty) o.trim(),
  ];
  return (label: spec.substring(0, sep).trim(), options: options);
}

// The distinct prompts a snippet asks the user for, in first-seen order. When
// one label appears more than once, its first set of options wins.
List<SnippetPrompt> snippetPrompts(String value) {
  final seen = <String>{};
  final prompts = <SnippetPrompt>[];
  for (final match in _placeholder.allMatches(value)) {
    final token = match.group(1)!.trim();
    if (!token.startsWith(_promptPrefix)) continue;
    final parsed = _parsePrompt(token.substring(_promptPrefix.length).trim());
    if (parsed.label.isEmpty || !seen.add(parsed.label)) continue;
    prompts.add(SnippetPrompt(parsed.label, options: parsed.options));
  }
  return prompts;
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
      final label = _parsePrompt(
        token.substring(_promptPrefix.length).trim(),
      ).label;
      return answers[label] ?? match.group(0)!;
    }
    return match.group(0)!;
  });
}
