class HashtagUtils {
  static final RegExp _tagPattern = RegExp(
    r'#[A-Za-z][A-Za-z0-9_]{1,49}',
    caseSensitive: false,
  );

  static List<String> extract(String text) {
    final seen = <String>{};
    final tags = <String>[];

    for (final match in _tagPattern.allMatches(text)) {
      final tag = normalize(match.group(0) ?? '');
      if (tag.isEmpty || seen.contains(tag)) {
        continue;
      }

      seen.add(tag);
      tags.add(tag);
    }

    return tags;
  }

  static String strip(String text) {
    return text
        .replaceAll(_tagPattern, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String normalize(String tag) {
    final normalized = tag
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .toLowerCase();
    return RegExp(r'^[a-z][a-z0-9_]{1,49}$').hasMatch(normalized)
        ? normalized
        : '';
  }
}
