/// Lightweight GitHub-flavored markdown → plain text for update dialogs.
class ReleaseNotesDisplay {
  static final _knownIssuePattern = RegExp(
    r'known\s+issue|known\s+bug|regression|avoid\s+updat|do\s+not\s+update|'
    r'broken\s+in\s+this|critical\s+bug',
    caseSensitive: false,
  );

  static bool mentionsKnownIssues(String? notes) {
    if (notes == null || notes.trim().isEmpty) return false;
    return _knownIssuePattern.hasMatch(notes);
  }

  static String formatForDisplay(String? raw) {
    if (raw == null) return '';
    var text = raw.trim();
    if (text.isEmpty) return '';

    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAll('**', '').replaceAll('__', '');
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '• ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
