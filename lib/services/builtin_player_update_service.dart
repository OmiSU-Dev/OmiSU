import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:omisu/models/embedded_core_config.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/services/logger_service.dart';

const _lemuroidCoresTagsUrl =
    'https://api.github.com/repos/Swordfish90/LemuroidCores/tags';
const _libretroDroidLatestUrl =
    'https://api.github.com/repos/Swordfish90/LibretroDroid/releases/latest';

final _log = LoggerService.instance;

class BuiltinPlayerUpdateResult {
  final String? coresVersionApplied;
  final int coresDownloaded;
  final int coresExpected;
  final String? engineVersionApplied;
  final bool engineUpdateFailed;
  final bool coresCheckFailed;
  final bool libretroDroidUpdateAvailable;
  final String? remoteLibretroDroidVersion;
  final String bundledLibretroDroidVersion;

  const BuiltinPlayerUpdateResult({
    this.coresVersionApplied,
    this.coresDownloaded = 0,
    this.coresExpected = 0,
    this.engineVersionApplied,
    this.engineUpdateFailed = false,
    this.coresCheckFailed = false,
    this.libretroDroidUpdateAvailable = false,
    this.remoteLibretroDroidVersion,
    this.bundledLibretroDroidVersion = '0.13.2',
  });

  bool get coresUpdateComplete =>
      coresVersionApplied != null && coresDownloaded >= coresExpected;

  bool get engineUpdateComplete =>
      engineVersionApplied != null && !engineUpdateFailed;

  bool get coresPartialFailure =>
      coresDownloaded > 0 && coresDownloaded < coresExpected;

  bool get anyComponentUpdated =>
      coresUpdateComplete || engineUpdateComplete;
}

/// Remote versions available for built-in player OTA, without downloading.
class BuiltinPlayerUpdatePreview {
  final String localCoresVersion;
  final String? remoteCoresTag;
  final bool coresUpdateAvailable;
  final String bundledLibretroDroidVersion;
  final String? remoteLibretroDroidVersion;
  final bool engineUpdateAvailable;
  final String? releaseNotes;

  const BuiltinPlayerUpdatePreview({
    required this.localCoresVersion,
    this.remoteCoresTag,
    this.coresUpdateAvailable = false,
    required this.bundledLibretroDroidVersion,
    this.remoteLibretroDroidVersion,
    this.engineUpdateAvailable = false,
    this.releaseNotes,
  });

  bool get hasAnyUpdate => coresUpdateAvailable || engineUpdateAvailable;
}

/// Keeps embedded libretro cores and LibretroDroid engine up to date from
/// upstream GitHub/JitPack when auto-update is enabled.
class BuiltinPlayerUpdateService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _engineTimeout = Duration(seconds: 180);

  static bool isVersionAtLeast(String current, String minimum) =>
      _meetsMinimumVersion(current, minimum);

  /// Fetches remote engine/cores versions only — for confirm-before-update UI.
  static Future<BuiltinPlayerUpdatePreview?> checkPreview() async {
    if (!Platform.isAndroid) return null;

    final bundledLibretro = await EmbeddedEmulatorService
        .getBundledLibretroDroidVersion();
    final localCoresVersion =
        await EmbeddedEmulatorService.getBuiltinCoresVersion();

    String? remoteLibretro;
    String? libretroReleaseNotes;
    var engineUpdateAvailable = false;
    try {
      final release = await _fetchLatestLibretroDroidRelease();
      remoteLibretro = release?.version;
      libretroReleaseNotes = release?.body;
      if (remoteLibretro != null &&
          remoteLibretro.isNotEmpty &&
          !isVersionAtLeast(bundledLibretro, remoteLibretro)) {
        engineUpdateAvailable = true;
      }
    } catch (e) {
      _log.w('BuiltinPlayerUpdateService: preview LibretroDroid check: $e');
    }

    String? remoteCoresTag;
    var coresUpdateAvailable = false;
    try {
      remoteCoresTag = await _fetchLatestLemuroidCoresTag();
      if (remoteCoresTag != null &&
          remoteCoresTag.isNotEmpty &&
          !isVersionAtLeast(localCoresVersion, remoteCoresTag)) {
        coresUpdateAvailable = true;
      }
    } catch (e) {
      _log.w('BuiltinPlayerUpdateService: preview cores check: $e');
    }

    if (!engineUpdateAvailable && !coresUpdateAvailable) return null;

    final notes = <String>[];
    if (engineUpdateAvailable) {
      if (libretroReleaseNotes != null &&
          libretroReleaseNotes.trim().isNotEmpty) {
        notes.add(libretroReleaseNotes.trim());
      }
    }
    if (coresUpdateAvailable && remoteCoresTag != null) {
      notes.add(
        'LemuroidCores: $localCoresVersion → $remoteCoresTag',
      );
    }

    return BuiltinPlayerUpdatePreview(
      localCoresVersion: localCoresVersion,
      remoteCoresTag: remoteCoresTag,
      coresUpdateAvailable: coresUpdateAvailable,
      bundledLibretroDroidVersion: bundledLibretro,
      remoteLibretroDroidVersion: remoteLibretro,
      engineUpdateAvailable: engineUpdateAvailable,
      releaseNotes: notes.isEmpty ? null : notes.join('\n\n'),
    );
  }

  static Future<BuiltinPlayerUpdateResult> checkAndUpdate({
    bool silent = true,
  }) async {
    if (!Platform.isAndroid) {
      return const BuiltinPlayerUpdateResult();
    }

    final bundledLibretro = await EmbeddedEmulatorService
        .getBundledLibretroDroidVersion();
    final localCoresVersion =
        await EmbeddedEmulatorService.getBuiltinCoresVersion();
    final expectedCores = EmbeddedCoreRegistry.uniqueCores.length;

    String? remoteLibretro;
    var libretroUpdateAvailable = false;
    try {
      final release = await _fetchLatestLibretroDroidRelease();
      remoteLibretro = release?.version;
      if (remoteLibretro != null &&
          remoteLibretro.isNotEmpty &&
          !isVersionAtLeast(bundledLibretro, remoteLibretro)) {
        libretroUpdateAvailable = true;
        if (!silent) {
          _log.i(
            'BuiltinPlayerUpdateService: LibretroDroid $bundledLibretro < '
            'remote $remoteLibretro — OTA engine update',
          );
        }
      }
    } catch (e) {
      _log.w('BuiltinPlayerUpdateService: LibretroDroid check failed: $e');
    }

    String? engineVersionApplied;
    var engineUpdateFailed = false;
    if (libretroUpdateAvailable && remoteLibretro != null) {
      try {
        final installed = await EmbeddedEmulatorService
            .downloadLibretroDroidEngine(remoteLibretro)
            .timeout(_engineTimeout);
        if (installed) {
          engineVersionApplied = remoteLibretro;
          _log.i(
            'BuiltinPlayerUpdateService: LibretroDroid engine updated to '
            '$remoteLibretro',
          );
        } else {
          engineUpdateFailed = true;
          _log.w(
            'BuiltinPlayerUpdateService: LibretroDroid engine OTA failed for '
            '$remoteLibretro',
          );
        }
      } catch (e) {
        engineUpdateFailed = true;
        _log.w('BuiltinPlayerUpdateService: engine download failed: $e');
      }
    }

    String? remoteCoresTag;
    try {
      remoteCoresTag = await _fetchLatestLemuroidCoresTag();
    } catch (e) {
      _log.w('BuiltinPlayerUpdateService: LemuroidCores tag fetch failed: $e');
      return BuiltinPlayerUpdateResult(
        engineVersionApplied: engineVersionApplied,
        engineUpdateFailed: engineUpdateFailed,
        coresCheckFailed: true,
        libretroDroidUpdateAvailable: libretroUpdateAvailable,
        remoteLibretroDroidVersion: remoteLibretro,
        bundledLibretroDroidVersion: bundledLibretro,
      );
    }

    if (remoteCoresTag == null ||
        remoteCoresTag.isEmpty ||
        isVersionAtLeast(localCoresVersion, remoteCoresTag)) {
      _log.i(
        'BuiltinPlayerUpdateService: cores up to date '
        '(local=$localCoresVersion remote=$remoteCoresTag)',
      );
      return BuiltinPlayerUpdateResult(
        engineVersionApplied: engineVersionApplied,
        engineUpdateFailed: engineUpdateFailed,
        libretroDroidUpdateAvailable: libretroUpdateAvailable,
        remoteLibretroDroidVersion: remoteLibretro,
        bundledLibretroDroidVersion: bundledLibretro,
      );
    }

    if (!silent) {
      _log.i(
        'BuiltinPlayerUpdateService: updating cores '
        '$localCoresVersion → $remoteCoresTag',
      );
    }

    final downloaded = await EmbeddedEmulatorService.downloadAllBuiltinCores(
      remoteCoresTag,
    );

    if (downloaded >= expectedCores) {
      await EmbeddedEmulatorService.setBuiltinCoresVersion(remoteCoresTag);
      _log.i(
        'BuiltinPlayerUpdateService: cores updated to $remoteCoresTag '
        '($downloaded/$expectedCores)',
      );
      return BuiltinPlayerUpdateResult(
        coresVersionApplied: remoteCoresTag,
        coresDownloaded: downloaded,
        coresExpected: expectedCores,
        engineVersionApplied: engineVersionApplied,
        engineUpdateFailed: engineUpdateFailed,
        libretroDroidUpdateAvailable: libretroUpdateAvailable,
        remoteLibretroDroidVersion: remoteLibretro,
        bundledLibretroDroidVersion: bundledLibretro,
      );
    }

    _log.w(
      'BuiltinPlayerUpdateService: partial core update '
      '($downloaded/$expectedCores) — keeping version $localCoresVersion',
    );
    return BuiltinPlayerUpdateResult(
      coresDownloaded: downloaded,
      coresExpected: expectedCores,
      engineVersionApplied: engineVersionApplied,
      engineUpdateFailed: engineUpdateFailed,
      libretroDroidUpdateAvailable: libretroUpdateAvailable,
      remoteLibretroDroidVersion: remoteLibretro,
      bundledLibretroDroidVersion: bundledLibretro,
    );
  }

  static Future<String?> _fetchLatestLemuroidCoresTag() async {
    final response = await http
        .get(Uri.parse(_lemuroidCoresTagsUrl), headers: _githubHeaders)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw HttpException('GitHub tags HTTP ${response.statusCode}');
    }
    final tags = jsonDecode(response.body) as List<dynamic>;
    if (tags.isEmpty) return null;
    final first = tags.first as Map<String, dynamic>;
    return first['name']?.toString();
  }

  static Future<({String version, String? body})?> _fetchLatestLibretroDroidRelease() async {
    final response = await http
        .get(Uri.parse(_libretroDroidLatestUrl), headers: _githubHeaders)
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw HttpException('GitHub release HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['prerelease'] == true) {
      return null;
    }
    final tag = body['tag_name']?.toString();
    if (tag == null) return null;
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    final notes = body['body']?.toString();
    return (version: version, body: notes);
  }

  static const _githubHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'OmiSU-BuiltinPlayerUpdater',
  };

  static bool _meetsMinimumVersion(String appVersion, String minimum) {
    List<int> parse(String v) =>
        v.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();
    final a = parse(appVersion);
    final m = parse(minimum);
    final len = a.length > m.length ? a.length : m.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (av != mv) return av > mv;
    }
    return true;
  }
}
