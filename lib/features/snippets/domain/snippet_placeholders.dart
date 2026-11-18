// Snippet and workflow text can carry placeholders in {{ }}:
//   {{host}} {{user}} {{port}}   fill from the connected server
//   {{Label}}                    ask for a value, shown as "Label"
//   {{Label[a,b,c]}}             ask with a dropdown of a, b, c
//   {{[a,b,c]}}                  ask with a dropdown, no label
final _placeholder = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

const _reserved = {'host', 'user', 'port'};

class SnippetContext {
  final String? host;
  final String? user;
  final int? port;
  const SnippetContext({this.host, this.user, this.port});
}

// A value the user is asked for. [key] identifies it in the answers map; [label]
// is what the prompt shows; [options] are the dropdown choices, if any.
class SnippetPrompt {
  final String key;
  final String label;
  final List<String> options;
  const SnippetPrompt({
    required this.key,
    required this.label,
    this.options = const [],
  });
}

bool snippetHasPlaceholders(String value) => _placeholder.hasMatch(value);

// The prompt a token describes, or null for a reserved context name. The key is
// the label, or the raw option list when unlabelled, so the same token always
// resolves to the same answer.
SnippetPrompt? _promptFor(String token) {
  if (_reserved.contains(token)) return null;

  final open = token.indexOf('[');
  if (open == -1 || !token.endsWith(']')) {
    return SnippetPrompt(key: token, label: token);
  }

  final label = token.substring(0, open).trim();
  final options = [
    for (final o in token.substring(open + 1, token.length - 1).split(','))
      if (o.trim().isNotEmpty) o.trim(),
  ];
  final key = label.isNotEmpty ? label : options.join(',');
  if (key.isEmpty) return null;
  return SnippetPrompt(key: key, label: label, options: options);
}

// The distinct prompts in first-seen order, deduplicated by key.
List<SnippetPrompt> snippetPrompts(String value) {
  final seen = <String>{};
  final prompts = <SnippetPrompt>[];
  for (final match in _placeholder.allMatches(value)) {
    final prompt = _promptFor(match.group(1)!.trim());
    if (prompt == null || !seen.add(prompt.key)) continue;
    prompts.add(prompt);
  }
  return prompts;
}

// Fills context and prompt tokens. A token with no value is left untouched, so a
// mistake shows up in the output rather than silently vanishing.
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
    final prompt = _promptFor(token);
    if (prompt == null) return match.group(0)!;
    return answers[prompt.key] ?? match.group(0)!;
  });
}
