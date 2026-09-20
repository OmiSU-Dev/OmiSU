import 'dart:io';

import 'package:omisu/services/embedded/libretro_cheat_system_map.dart';
import 'package:path/path.dart' as p;

/// Locates RetroArch-style `.cht` files from a local [libretro-database](https://github.com/libretro/libretro-database) tree.
///
/// The full `cht/` tree is ~250 MB — ship it on storage under app user-data or next to your ROM library, not in the APK.
class LibretroCheatDatabase {
  LibretroCheatDatabase._();

  static final Map<String, List<({String stem, File file})>> _chtIndexCache = {};

  /// Normalizes a ROM or cheat filename stem for fuzzy comparison.
  static String normalizeStem(String name) {
    final stem = p.basenameWithoutExtension(name).toLowerCase();
    return stem
        .replaceAll(RegExp(r'[_\-\.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Title stem without region tags — better ROM ↔ libretro `.cht` matching.
  static String normalizeTitleCore(String name) {
    var s = normalizeStem(name);
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static Set<String> needlesForGame({
    required String romname,
    String? displayName,
    String? titleName,
    String? romPath,
  }) {
    final needles = <String>{};
    void add(String? value) {
      if (value == null || value.trim().isEmpty) return;
      needles.add(normalizeStem(value));
      needles.add(normalizeTitleCore(value));
    }

    add(romname);
    add(displayName);
    add(titleName);
    if (romPath != null && romPath.isNotEmpty) {
      add(p.basename(romPath));
    }
    return needles;
  }

  /// Candidate `.cht` paths for a game, best match first.
  static Future<List<File>> findCheatFiles({
    required String systemFolderName,
    required String romname,
    String? romPath,
    String? displayName,
    String? titleName,
    required List<Directory> cheatRoots,
  }) async {
    final chtFolder = LibretroCheatSystemMap.chtFolderForSystem(systemFolderName);
    if (chtFolder == null || cheatRoots.isEmpty) return const [];

    final needles = needlesForGame(
      romname: romname,
      displayName: displayName,
      titleName: titleName,
      romPath: romPath,
    );

    final scored = <({int score, File file})>[];

    for (final root in cheatRoots) {
      if (!await root.exists()) continue;
      final systemDir = Directory(p.join(root.path, chtFolder));
      if (!await systemDir.exists()) continue;

      final direct = await _findDirectChtFile(
        systemDir,
        romname: romname,
        romPath: romPath,
        displayName: displayName,
        titleName: titleName,
      );
      if (direct != null) {
        return [direct];
      }

      for (final entry in await _indexedChtFiles(systemDir)) {
        for (final needle in needles) {
          final score = _scoreMatch(needle, entry.stem);
          if (score > 0) {
            scored.add((score: score, file: entry.file));
          }
        }
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final files = <File>[];
    for (final entry in scored) {
      final path = entry.file.path;
      if (seen.add(path)) files.add(entry.file);
    }
    return files;
  }

  /// Best matching `.cht` file, or null.
  static Future<File?> findBestCheatFile({
    required String systemFolderName,
    required String romname,
    String? romPath,
    String? displayName,
    String? titleName,
    required List<Directory> cheatRoots,
  }) async {
    final files = await findCheatFiles(
      systemFolderName: systemFolderName,
      romname: romname,
      romPath: romPath,
      displayName: displayName,
      titleName: titleName,
      cheatRoots: cheatRoots,
    );
    return files.isEmpty ? null : files.first;
  }

  static Future<List<({String stem, File file})>> _indexedChtFiles(
    Directory systemDir,
  ) async {
    final key = systemDir.path;
    final cached = _chtIndexCache[key];
    if (cached != null) return cached;

    final entries = <({String stem, File file})>[];
    await for (final entity in systemDir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.cht')) {
        continue;
      }
      entries.add((stem: normalizeStem(entity.path), file: entity));
    }
    _chtIndexCache[key] = entries;
    return entries;
  }

  /// Fast path when ROM and libretro `.cht` share the same filename stem.
  static Future<File?> _findDirectChtFile(
    Directory systemDir, {
    required String romname,
    String? romPath,
    String? displayName,
    String? titleName,
  }) async {
    final stems = <String>{};
    void add(String? value) {
      if (value == null || value.trim().isEmpty) return;
      stems.add(p.basenameWithoutExtension(value.trim()));
    }

    add(romname);
    add(displayName);
    add(titleName);
    if (romPath != null && romPath.isNotEmpty) {
      add(p.basename(romPath));
    }

    for (final stem in stems) {
      final file = File(p.join(systemDir.path, '$stem.cht'));
      if (await file.exists()) return file;
    }
    return null;
  }

  static int _scoreMatch(String needle, String chtStem) {
    if (needle.isEmpty || chtStem.isEmpty) return 0;
    if (needle == chtStem) return 100;

    final coreNeedle = normalizeTitleCore(needle);
    final coreCht = normalizeTitleCore(chtStem);
    if (coreNeedle.isNotEmpty && coreCht.isNotEmpty) {
      if (coreNeedle == coreCht) return 95;
      if (coreCht.startsWith(coreNeedle) || coreNeedle.startsWith(coreCht)) {
        return 88;
      }
      if (coreCht.contains(coreNeedle) || coreNeedle.contains(coreCht)) {
        return 78;
      }
    }

    if (chtStem.startsWith(needle)) return 80;
    if (needle.startsWith(chtStem)) return 75;
    if (chtStem.contains(needle)) return 60;
    if (needle.contains(chtStem)) return 55;
    return 0;
  }

  /// Standard locations for the libretro `cht/` tree (existing dirs only).
  static Future<List<Directory>> discoverCheatRoots({
    String? userDataPath,
    String? romPath,
  }) async {
    final roots = <Directory>[];
    final seen = <String>{};

    void add(String path) {
      if (seen.add(path)) roots.add(Directory(path));
    }

    if (userDataPath != null && userDataPath.isNotEmpty) {
      add(p.join(userDataPath, 'libretro-database', 'cht'));
      add(p.join(userDataPath, 'cheats'));
    }

    if (romPath != null && romPath.isNotEmpty) {
      final romFile = File(romPath);
      final romDir = romFile.parent;
      add(p.join(romDir.path, 'cheats'));
      add(p.join(romDir.path, 'cht'));

      var dir = romDir;
      for (var depth = 0; depth < 8; depth++) {
        add(p.join(dir.path, 'libretro-database-master', 'cht'));
        add(p.join(dir.path, 'libretro-database', 'cht'));
        add(p.join(dir.path, 'database', 'cht'));
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    }

    if (Platform.isLinux) {
      add('/usr/share/libretro/database/cht');
    }

    final existing = <Directory>[];
    for (final dir in roots) {
      if (await dir.exists()) existing.add(dir);
    }
    return existing;
  }
}
