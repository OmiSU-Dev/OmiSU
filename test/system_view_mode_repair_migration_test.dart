import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:omisu/data/datasources/sqlite_migrations.dart';

/// Tests for migration v114, which repairs `user_config.system_view_mode`
/// values that the games view used to write into it.
///
/// The game view settings screen (removed in #317) saved the games layout
/// through a writer that mirrored it onto `system_view_mode` as well. The
/// systems view understands only `grid` and `carousel`, so anyone who picked
/// the `list` games layout ended up with a systems mode nothing recognises:
/// the view falls back to the grid and the sort dropdown shows no option as
/// selected. The writer is fixed; this migration cleans up after it.
void main() {
  late Database db;

  setUp(() {
    db = sqlite3.openInMemory();
    db.execute('''
      CREATE TABLE user_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        system_view_mode TEXT DEFAULT 'grid',
        game_view_mode TEXT DEFAULT 'list'
      )
    ''');
  });

  tearDown(() {
    db.close();
  });

  Future<void> runV114() => SqliteMigrations.migrateToVersion(db, 114);

  void seed(String? systemViewMode, {String gameViewMode = 'list'}) {
    db.execute(
      'INSERT INTO user_config (id, system_view_mode, game_view_mode) '
      'VALUES (1, ?, ?)',
      [systemViewMode, gameViewMode],
    );
  }

  String? storedSystemViewMode() {
    final rows = db.select('SELECT system_view_mode FROM user_config');
    return rows.first['system_view_mode'] as String?;
  }

  group('migration v114', () {
    test(
      'a games-view value written into the column is reset to grid',
      () async {
        seed('list');

        await runV114();

        expect(storedSystemViewMode(), 'grid');
      },
    );

    test('a deliberate carousel choice is left alone', () async {
      seed('carousel');

      await runV114();

      expect(storedSystemViewMode(), 'carousel');
    });

    test('an existing grid choice is left alone', () async {
      seed('grid');

      await runV114();

      expect(storedSystemViewMode(), 'grid');
    });

    test('a null column is filled in with the default', () async {
      seed(null);

      await runV114();

      expect(storedSystemViewMode(), 'grid');
    });

    test('the games view mode itself is untouched', () async {
      seed('list', gameViewMode: 'list');

      await runV114();

      final rows = db.select('SELECT game_view_mode FROM user_config');
      expect(rows.first['game_view_mode'], 'list');
    });

    test('an empty user_config is a no-op', () async {
      await runV114();

      final rows = db.select('SELECT COUNT(*) AS n FROM user_config');
      expect(rows.first['n'], 0);
    });

    test('a database without the column does not throw', () async {
      db.execute('DROP TABLE user_config');
      db.execute('CREATE TABLE user_config (id INTEGER PRIMARY KEY)');

      await expectLater(runV114(), completes);
    });
  });
}
