import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/builtin_player_update_service.dart';

void main() {
  test('isVersionAtLeast compares semver tags', () {
    expect(
      BuiltinPlayerUpdateService.isVersionAtLeast('1.17.0', '1.17.0'),
      isTrue,
    );
    expect(
      BuiltinPlayerUpdateService.isVersionAtLeast('1.18.0', '1.17.0'),
      isTrue,
    );
    expect(
      BuiltinPlayerUpdateService.isVersionAtLeast('1.17.0', '1.18.0'),
      isFalse,
    );
  });
}
