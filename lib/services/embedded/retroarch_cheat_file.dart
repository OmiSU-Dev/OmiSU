/// Parses a subset of RetroArch `.cht` files.
List<({String description, String code})> parseRetroArchCheatFile(String content) {
  final lines = content.split(RegExp(r'\r?\n'));
  final descPattern = RegExp(r'^cheat(\d+)_desc\s*=\s*"(.*)"\s*$');
  final codePattern = RegExp(r'^cheat(\d+)_code\s*=\s*"(.*)"\s*$');
  final byIndex = <int, ({String? description, String? code})>{};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final descMatch = descPattern.firstMatch(trimmed);
    if (descMatch != null) {
      final index = int.parse(descMatch.group(1)!);
      final entry = byIndex[index] ?? (description: null, code: null);
      byIndex[index] = (description: descMatch.group(2), code: entry.code);
      continue;
    }
    final codeMatch = codePattern.firstMatch(trimmed);
    if (codeMatch != null) {
      final index = int.parse(codeMatch.group(1)!);
      final entry = byIndex[index] ?? (description: null, code: null);
      byIndex[index] = (description: entry.description, code: codeMatch.group(2));
    }
  }

  final sortedKeys = byIndex.keys.toList()..sort();
  final out = <({String description, String code})>[];
  for (final key in sortedKeys) {
    final entry = byIndex[key]!;
    final code = entry.code?.trim() ?? '';
    final description = entry.description?.trim() ?? 'Cheat $key';
    if (code.isEmpty) continue;
    out.add((description: description, code: code));
  }
  return out;
}
