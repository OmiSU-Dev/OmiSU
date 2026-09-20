import 'dart:io';

import 'package:omisu/models/system_model.dart';
import 'package:omisu/utils/rom_folder_path.dart';
import 'package:path/path.dart' as path;

/// Resolves a user's physical ROM subfolder to an OmiSU system id.
///
/// Game titles still come from ROM filenames and scrapers — only the
/// folder→system link uses this resolver.
class RomFolderSystemResolver {
  RomFolderSystemResolver._();

  static const _skipFolderNames = {'systems', 'media', 'bios', 'firmware'};

  static const _ambiguousExtensions = {
    'zip',
    '7z',
    'bin',
    'rom',
    'rar',
  };

  /// Normalizes folder labels for alias comparison (No-Intro, ES-DE, etc.).
  static String normalizeLabel(String label) => normalizeRomFolderLabel(label);

  static bool shouldSkipFolderLabel(String label) {
    if (label.isEmpty) return true;
    if (label.startsWith('.')) return true;
    return _skipFolderNames.contains(label.toLowerCase());
  }

  /// Maps every physical subfolder path under [rootFoldersMap] to a system id.
  static Future<Map<String, String>> buildSubdirSystemMap({
    required Map<String, Map<String, String>> rootFoldersMap,
    required List<SystemModel> availableSystems,
  }) async {
    final result = <String, String>{};
    for (final subdirs in rootFoldersMap.values) {
      for (final entry in subdirs.entries) {
        if (shouldSkipFolderLabel(entry.key)) continue;
        final systemId = await resolveSystemId(
          folderLabel: entry.key,
          folderPath: entry.value,
          availableSystems: availableSystems,
        );
        if (systemId != null) {
          result[entry.value] = systemId;
        }
      }
    }
    return result;
  }

  /// Returns the canonical system id for [folderLabel]/[folderPath], or null.
  static Future<String?> resolveSystemId({
    required String folderLabel,
    required String folderPath,
    required List<SystemModel> availableSystems,
  }) async {
    final fromLabel = resolveSystemIdFromLabel(
      folderLabel,
      availableSystems: availableSystems,
    );
    if (fromLabel != null) return fromLabel;

    return _inferSystemIdFromFiles(
      folderPath,
      availableSystems: availableSystems,
    );
  }

  /// Label-only resolution (aliases, normalization, keywords).
  static String? resolveSystemIdFromLabel(
    String folderLabel, {
    required List<SystemModel> availableSystems,
  }) {
    if (shouldSkipFolderLabel(folderLabel)) return null;

    final inMemory = _matchAvailableSystems(folderLabel, availableSystems);
    if (inMemory?.id != null) return inMemory!.id;

    final keywordId = _matchKeywordSystemId(normalizeLabel(folderLabel));
    if (keywordId != null &&
        availableSystems.any((s) => s.id == keywordId)) {
      return keywordId;
    }

    return null;
  }

  static SystemModel? _matchAvailableSystems(
    String folderLabel,
    List<SystemModel> availableSystems,
  ) {
    final lowerInput = folderLabel.toLowerCase();
    final normalizedInput = normalizeLabel(folderLabel);

    bool matches(String candidate) {
      final lower = candidate.toLowerCase();
      if (lower == lowerInput) return true;
      if (normalizeLabel(candidate) == normalizedInput) return true;
      if (lower.replaceAll(' ', '') == lowerInput.replaceAll(' ', '')) {
        return true;
      }
      return false;
    }

    for (final system in availableSystems) {
      if (matches(system.folderName)) return system;
      for (final alias in system.folders) {
        if (matches(alias)) return system;
      }
    }
    return null;
  }

  static String? _matchKeywordSystemId(String normalized) {
    bool hasWord(String word) =>
        RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(normalized);

    if (hasWord('snes') ||
        normalized.contains('super nintendo') ||
        normalized.contains('super famicom')) {
      return 'snes';
    }
    if (hasWord('gbc') || normalized.contains('game boy color')) {
      return 'gbc';
    }
    if (hasWord('gba') || normalized.contains('game boy advance')) {
      return 'gba';
    }
    if (hasWord('gb') || normalized.contains('game boy')) {
      return 'gb';
    }
    if (hasWord('nes') ||
        normalized.contains('nintendo entertainment') ||
        normalized.contains('famicom')) {
      return 'nes';
    }
    if (hasWord('psp') || normalized.contains('playstation portable')) {
      return 'psp';
    }
    if (hasWord('ps2') || normalized.contains('playstation 2')) {
      return 'ps2';
    }
    if (hasWord('ps3') || normalized.contains('playstation 3')) {
      return 'ps3';
    }
    if (hasWord('psx') ||
        hasWord('ps1') ||
        normalized.contains('playstation') && !normalized.contains('portable')) {
      return 'psx';
    }
    if (hasWord('n64') || normalized.contains('nintendo 64')) {
      return 'n64';
    }
    if (hasWord('nds') || normalized.contains('nintendo ds')) {
      return 'nds';
    }
    if (hasWord('3ds') || normalized.contains('nintendo 3ds')) {
      return '3ds';
    }
    if (hasWord('megadrive') ||
        hasWord('genesis') ||
        normalized.contains('mega drive')) {
      return 'megadrive';
    }
    if (hasWord('dreamcast')) {
      return 'dreamcast';
    }
    if (hasWord('saturn')) {
      return 'saturn';
    }
    if (hasWord('gc') ||
        hasWord('ngc') ||
        normalized.contains('gamecube') ||
        normalized.contains('game cube')) {
      return 'gc';
    }
    if (hasWord('wii')) {
      return 'wii';
    }
    return null;
  }

  static Future<String?> _inferSystemIdFromFiles(
    String folderPath, {
    required List<SystemModel> availableSystems,
    int sampleLimit = 64,
  }) async {
    if (Platform.isAndroid && folderPath.startsWith('content://')) {
      return null;
    }

    final dir = Directory(folderPath);
    if (!await dir.exists()) return null;

    final scores = <String, int>{};
    var sampled = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (sampled >= sampleLimit) break;

        var ext = path.extension(entity.path).toLowerCase();
        if (ext.startsWith('.')) ext = ext.substring(1);
        if (ext.isEmpty) continue;
        sampled++;

        for (final system in availableSystems) {
          if (system.id == null || system.isVirtual) continue;
          if (!system.extensions.contains(ext)) continue;
          scores.update(system.id!, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    } catch (_) {
      return null;
    }

    if (scores.isEmpty) return null;

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winner = sorted.first;
    if (sorted.length > 1 && winner.value == sorted[1].value) {
      // Tie — only accept if the winning extension is unambiguous.
      final winnerExt = await _dominantExtension(folderPath, sampleLimit);
      if (winnerExt == null || _ambiguousExtensions.contains(winnerExt)) {
        return null;
      }
    }

    return winner.key;
  }

  static Future<String?> _dominantExtension(
    String folderPath,
    int sampleLimit,
  ) async {
    final counts = <String, int>{};
    var sampled = 0;
    try {
      await for (final entity in Directory(folderPath).list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        if (sampled >= sampleLimit) break;
        var ext = path.extension(entity.path).toLowerCase();
        if (ext.startsWith('.')) ext = ext.substring(1);
        if (ext.isEmpty) continue;
        sampled++;
        counts.update(ext, (v) => v + 1, ifAbsent: () => 1);
      }
    } catch (_) {
      return null;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
