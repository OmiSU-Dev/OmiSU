import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/libretro_cheat_database.dart';
import 'package:omisu/services/embedded/libretro_cheat_system_map.dart';
import 'package:path/path.dart' as p;

void main() {
  test('maps nes folder to libretro cht directory', () {
    expect(
      LibretroCheatSystemMap.chtFolderForSystem('fc'),
      'Nintendo - Nintendo Entertainment System',
    );
  });

  test('normalizeStem lowercases and collapses separators', () {
    expect(
      LibretroCheatDatabase.normalizeStem('Super Mario Bros. (USA).nes'),
      'super mario bros (usa)',
    );
  });

  test('findBestCheatFile matches ROM filename to cht stem', () async {
    final root = await Directory.systemTemp.createTemp('omisu_cht_test');
    final systemDir = Directory(
      p.join(
        root.path,
        'Nintendo - Nintendo Entertainment System',
      ),
    );
    await systemDir.create(recursive: true);
    final cht = File(
      p.join(systemDir.path, '10-Yard Fight (USA, Europe).cht'),
    );
    await cht.writeAsString('cheats = 1\ncheat0_desc = "x"\ncheat0_code = "00"\n');

    final found = await LibretroCheatDatabase.findBestCheatFile(
      systemFolderName: 'nes',
      romname: '10-Yard Fight (USA, Europe).nes',
      cheatRoots: [root],
    );

    expect(found?.path, cht.path);
    await root.delete(recursive: true);
  });

  test('matches Adventure Island II zip name to GB libretro cht title', () async {
    final root = await Directory.systemTemp.createTemp('omisu_cht_test2');
    final systemDir = Directory(
      p.join(root.path, 'Nintendo - Game Boy'),
    );
    await systemDir.create(recursive: true);
    final cht = File(
      p.join(
        systemDir.path,
        'Adventure Island II - Aliens in Paradise (USA, Europe).cht',
      ),
    );
    await cht.writeAsString('cheats = 1\ncheat0_desc = "x"\ncheat0_code = "00"\n');

    final found = await LibretroCheatDatabase.findBestCheatFile(
      systemFolderName: 'gb',
      romname: 'Adventure Island II (USA).zip',
      displayName: 'Adventure Island II',
      cheatRoots: [root],
    );

    expect(found?.path, cht.path);
    await root.delete(recursive: true);
  });
}
