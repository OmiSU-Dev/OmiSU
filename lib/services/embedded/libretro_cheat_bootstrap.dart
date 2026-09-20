import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omisu/services/config_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:path/path.dart' as p;

/// Installs bundled libretro-database `cht/` files into app user-data on Android.
class LibretroCheatBootstrap {
  LibretroCheatBootstrap._();

  static const assetPath = 'assets/data/libretro_cheats.tar.gz';
  static const packVersion = 1;

  static final _log = LoggerService.instance;
  static Future<void>? _installFuture;

  /// Idempotent; safe to call multiple times.
  static Future<void> ensureInstalled() {
    if (!Platform.isAndroid) return Future.value();
    return _installFuture ??= _ensureInstalledOnce();
  }

  static Future<void> _ensureInstalledOnce() async {
    try {
      final userData = await ConfigService.getUserDataPath();
      final packDir = Directory(p.join(userData, 'libretro-database'));
      final marker = File(p.join(packDir.path, '.cheat_pack_version'));
      final chtRoot = Directory(p.join(packDir.path, 'cht'));

      if (await _isInstalled(marker, chtRoot)) {
        _log.i('Libretro cheat pack already installed (v$packVersion)');
        return;
      }

      _log.i('Installing bundled libretro cheat pack (v$packVersion)…');
      final byteData = await rootBundle.load(assetPath);
      final gzBytes = byteData.buffer.asUint8List();
      final tarBytes = GZipDecoder().decodeBytes(gzBytes);
      final archive = TarDecoder().decodeBytes(tarBytes);

      await packDir.create(recursive: true);
      if (await chtRoot.exists()) {
        await chtRoot.delete(recursive: true);
      }
      await chtRoot.create(recursive: true);

      var filesWritten = 0;
      for (final entry in archive) {
        if (!entry.isFile || entry.name.isEmpty) continue;
        final normalized = p.normalize(entry.name);
        if (normalized.startsWith('..')) continue;
        final outFile = File(p.join(chtRoot.path, normalized));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(entry.content, flush: false);
        filesWritten++;
      }

      await marker.writeAsString('$packVersion');
      _log.i('Libretro cheat pack installed ($filesWritten .cht files)');
    } on FlutterError catch (e) {
      // Asset missing in debug builds that skipped sync script.
      _log.w('Bundled libretro cheats not in APK: $e');
    } catch (e, st) {
      _log.e('Libretro cheat pack install failed: $e\n$st');
    }
  }

  static Future<bool> _isInstalled(File marker, Directory chtRoot) async {
    if (!await marker.exists() || !await chtRoot.exists()) return false;
    final version = int.tryParse((await marker.readAsString()).trim());
    if (version == null || version < packVersion) return false;
    final sample = await chtRoot.list().take(1).toList();
    return sample.isNotEmpty;
  }
}
