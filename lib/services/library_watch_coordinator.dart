import 'dart:async';
import 'dart:io';

import 'package:omisu/models/system_model.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/repositories/system_repository.dart';
import 'package:omisu/services/auto_scrape_coordinator.dart';
import 'package:omisu/services/game_service.dart';
import 'package:omisu/services/global_notification_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:path/path.dart' as p;

/// Watches configured ROM folders on desktop platforms and triggers silent
/// rescans when files change or when the app returns to the foreground.
class LibraryWatchCoordinator {
  LibraryWatchCoordinator._();

  static final LibraryWatchCoordinator instance = LibraryWatchCoordinator._();

  static final _log = LoggerService.instance;
  static const _debounceDuration = Duration(seconds: 4);
  static const _autoScanNotificationId = 'library-auto-scan';

  SqliteConfigProvider? _provider;
  final Map<String, StreamSubscription<FileSystemEvent>> _watchSubscriptions =
      {};
  Timer? _debounceTimer;
  Timer? _resumeDebounceTimer;
  final Set<String> _pendingSystemFolders = {};

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  void attach(SqliteConfigProvider provider) {
    _provider = provider;
    refreshWatchers();
  }

  void detach() {
    _cancelAllWatchers();
    _debounceTimer?.cancel();
    _resumeDebounceTimer?.cancel();
    _pendingSystemFolders.clear();
    _provider = null;
  }

  /// (Re)starts filesystem watchers according to the current config.
  void refreshWatchers() {
    _cancelAllWatchers();
    final provider = _provider;
    if (provider == null || !_isDesktop) return;
    if (!provider.config.autoScanOnChange) return;

    for (final romFolder in provider.config.romFolders) {
      if (romFolder.isEmpty || romFolder.startsWith('content://')) continue;
      try {
        final dir = Directory(romFolder);
        if (!dir.existsSync()) continue;
        final sub = dir.watch(recursive: true).listen(
          _onWatchEvent,
          onError: (Object e) {
            _log.w('Library watch error for $romFolder: $e');
          },
        );
        _watchSubscriptions[romFolder] = sub;
      } catch (e) {
        _log.w('Failed to watch ROM folder $romFolder: $e');
      }
    }
  }

  /// Debounced silent rescan of all detected systems when the app resumes.
  void onAppResumed() {
    final provider = _provider;
    if (provider == null || !provider.config.autoScanOnResume) return;

    _resumeDebounceTimer?.cancel();
    _resumeDebounceTimer = Timer(_debounceDuration, () {
      unawaited(_rescanAllDetectedSystems());
    });
  }

  void _cancelAllWatchers() {
    for (final sub in _watchSubscriptions.values) {
      unawaited(sub.cancel());
    }
    _watchSubscriptions.clear();
  }

  void _onWatchEvent(FileSystemEvent event) {
    final systemFolder = _systemFolderForPath(event.path);
    if (systemFolder != null) {
      _pendingSystemFolders.add(systemFolder);
    }
    _scheduleDebouncedScan();
  }

  String? _systemFolderForPath(String eventPath) {
    final provider = _provider;
    if (provider == null) return null;

    final normalizedEvent = p.normalize(eventPath);
    for (final romFolder in provider.config.romFolders) {
      if (romFolder.isEmpty || romFolder.startsWith('content://')) continue;
      final normalizedRom = p.normalize(romFolder);
      final prefix = normalizedRom.endsWith(p.separator)
          ? normalizedRom
          : '$normalizedRom${p.separator}';
      if (!normalizedEvent.startsWith(prefix) &&
          normalizedEvent != normalizedRom) {
        continue;
      }
      if (normalizedEvent == normalizedRom) continue;
      final relative = normalizedEvent.substring(prefix.length);
      if (relative.isEmpty) continue;
      final firstSegment = p.split(relative).first;
      if (firstSegment.isNotEmpty) {
        return firstSegment;
      }
    }
    return null;
  }

  void _scheduleDebouncedScan() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(_runPendingScans());
    });
  }

  Future<void> _runPendingScans() async {
    final provider = _provider;
    if (provider == null) return;
    if (GameService.isGameLaunchInProgress || provider.isScanning) {
      _scheduleDebouncedScan();
      return;
    }

    final folders = _pendingSystemFolders.toList();
    _pendingSystemFolders.clear();
    if (folders.isEmpty) return;

    for (final folderName in folders) {
      await _rescanSystemFolder(folderName);
    }
  }

  Future<void> _rescanAllDetectedSystems() async {
    final provider = _provider;
    if (provider == null) return;
    if (GameService.isGameLaunchInProgress || provider.isScanning) return;

    for (final system in provider.detectedRealSystems) {
      await _rescanSystem(system);
    }
  }

  Future<void> _rescanSystemFolder(String folderName) async {
    final provider = _provider;
    if (provider == null) return;

    SystemModel? system = provider.detectedSystems
        .where((s) => s.folderName == folderName)
        .firstOrNull;
    system ??= await SystemRepository.getSystemByFolderName(folderName);
    if (system == null) return;

    await _rescanSystem(system);
  }

  Future<void> _rescanSystem(SystemModel system) async {
    final provider = _provider;
    if (provider == null) return;
    if (GameService.isGameLaunchInProgress || provider.isScanning) return;

    final summary = await provider.rescanSystemSilent(system);
    if (summary.added <= 0) return;

    GlobalNotificationService().show(
      id: _autoScanNotificationId,
      title: 'Library updated',
      message:
          '${summary.added} new game(s) found in ${summary.systemName}',
      type: GlobalNotificationType.success,
    );
    unawaited(
      AutoScrapeCoordinator.instance.onGamesAdded(
        system.folderName,
        summary.added,
      ),
    );
  }
}
