import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/data/datasources/sqlite_service.dart';

import 'database_test_helper.dart';

/// [SqliteService.saveUserConfig] used to mirror a `gameViewMode` write onto
/// `system_view_mode` as well — a leftover from before the two were separate
/// columns. The columns do not share a value domain: the games view also
/// accepts `list`, which nothing on the systems side recognises, so writing
/// the games view mode on its own silently dropped the systems view back to
/// the grid with no option showing as selected.
///
/// Every production write currently names both modes, and the systems one is
/// applied second, so the mapping was masked. These tests write the game mode
/// alone, which is the only shape that shows it.
void main() {
  final dbHelper = DatabaseTestHelper();

  setUp(() async => dbHelper.setUp());
  tearDown(() async => dbHelper.tearDown());

  group('game view mode writes', () {
    test(
      'writing the game view mode leaves the system view mode alone',
      () async {
        await SqliteService.saveUserConfig(systemViewMode: 'carousel');

        await SqliteService.saveUserConfig(gameViewMode: 'list');

        final stored = await SqliteService.getUserConfig();
        expect(stored?['game_view_mode'].toString(), 'list');
        expect(stored?['system_view_mode'].toString(), 'carousel');
      },
    );

    test('both modes are still written when both are named', () async {
      await SqliteService.saveUserConfig(
        gameViewMode: 'carousel',
        systemViewMode: 'grid',
      );

      final stored = await SqliteService.getUserConfig();
      expect(stored?['game_view_mode'].toString(), 'carousel');
      expect(stored?['system_view_mode'].toString(), 'grid');
    });
  });
}
