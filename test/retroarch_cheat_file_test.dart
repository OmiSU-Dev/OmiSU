import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/retroarch_cheat_file.dart';

void main() {
  test('parses cheat desc and code lines in index order', () {
    const content = '''
cheats = 2
cheat0_desc = "Infinite lives"
cheat0_code = "01234567"
cheat1_desc = "Max coins"
cheat1_code = "89ABCDEF"
''';
    final cheats = parseRetroArchCheatFile(content);
    expect(cheats.length, 2);
    expect(cheats[0].description, 'Infinite lives');
    expect(cheats[0].code, '01234567');
    expect(cheats[1].description, 'Max coins');
    expect(cheats[1].code, '89ABCDEF');
  });

  test('skips entries without code', () {
    const content = '''
cheat0_desc = "No code"
''';
    expect(parseRetroArchCheatFile(content), isEmpty);
  });
}
