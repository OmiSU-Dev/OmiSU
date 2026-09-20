import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/utils/release_notes_display.dart';

void main() {
  test('formatForDisplay unwraps inline code instead of literal \$1', () {
    const raw = 'Release from `abc123` on `main`, bump `version` in `pubspec.yaml`.';
    final out = ReleaseNotesDisplay.formatForDisplay(raw);
    expect(out, contains('abc123'));
    expect(out, contains('pubspec.yaml'));
    expect(out, isNot(contains(r'$1')));
  });

  test('formatForDisplay strips basic markdown', () {
    const raw = '## Fixes\n\n**Crash** on boot\n\n[Details](https://example.com)';
    final out = ReleaseNotesDisplay.formatForDisplay(raw);
    expect(out, contains('Fixes'));
    expect(out, contains('Crash'));
    expect(out, isNot(contains('**')));
    expect(out, isNot(contains('https://')));
  });

  test('mentionsKnownIssues detects warning phrases', () {
    expect(
      ReleaseNotesDisplay.mentionsKnownIssues('Known issue: saves may corrupt'),
      isTrue,
    );
    expect(ReleaseNotesDisplay.mentionsKnownIssues('Bug fixes only'), isFalse);
  });
}
