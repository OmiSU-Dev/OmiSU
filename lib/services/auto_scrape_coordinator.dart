import 'dart:async';
import 'dart:io';

import 'package:omisu/data/datasources/sqlite_config_service.dart';
import 'package:omisu/repositories/scraper_repository.dart';
import 'package:omisu/repositories/system_repository.dart';
import 'package:omisu/services/global_notification_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/screenscraper_service.dart';

class _ScrapeJob {
  final String systemFolderName;

  /// When set, only the first [limit] unscraped ROMs are processed. When null,
  /// every ROM that still lacks metadata is scraped.
  final int? limit;

  const _ScrapeJob(this.systemFolderName, {this.limit});
}

/// Queues background ScreenScraper passes for newly discovered ROMs.
class AutoScrapeCoordinator {
  AutoScrapeCoordinator._();

  static final AutoScrapeCoordinator instance = AutoScrapeCoordinator._();

  static final _log = LoggerService.instance;
  static const _notificationId = 'auto-scrape-batch';
  static const _missingCredsNotificationId = 'auto-scrape-no-credentials';
  static const _startedNotificationId = 'auto-scrape-started';

  bool _processing = false;
  bool _missingCredsNotified = false;
  final List<_ScrapeJob> _queue = [];

  Future<void> onGamesAdded(String systemFolderName, int addedCount) async {
    if (addedCount <= 0) return;
    _enqueue(_ScrapeJob(systemFolderName, limit: addedCount));
  }

  /// Called after a full library scan finishes. Scrapes every ROM that still
  /// lacks metadata for each [systemFolderName], not only the ones added in the
  /// last pass (rescans report `added=0` even on a fresh library).
  Future<void> onLibraryScanComplete(Iterable<String> systemFolderNames) async {
    for (final folder in systemFolderNames) {
      _enqueue(_ScrapeJob(folder));
    }
  }

  void _enqueue(_ScrapeJob job) {
    _queue.add(job);
    if (!_processing) {
      unawaited(_processQueue());
    }
  }

  Future<void> _processQueue() async {
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        await _processJob(job);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _processJob(_ScrapeJob job) async {
    try {
      final config = await SqliteConfigService.loadConfig();
      if (!config.autoScrapeNewGames) return;
      if (!await ScreenScraperService.hasSavedCredentials()) {
        _notifyMissingCredentialsOnce();
        return;
      }
      if (ScreenScraperService.isMetadataScrapingRunning) return;
      if (config.autoScrapeWifiOnly && !await _isOnWifi()) return;

      final system = await SystemRepository.getSystemByFolderName(
        job.systemFolderName,
      );
      final appSystemId = system?.id;
      if (appSystemId == null || appSystemId.isEmpty) return;

      final roms = await ScraperRepository.getRomsForScraping(
        appSystemId,
        'new_only',
      );
      final toScrape = job.limit == null
          ? roms
          : roms.take(job.limit!).toList();
      if (toScrape.isEmpty) return;

      GlobalNotificationService().show(
        id: _startedNotificationId,
        title: 'Downloading artwork',
        message:
            'Scraping ${toScrape.length} game(s) for '
            '${system?.realName ?? job.systemFolderName}…',
        type: GlobalNotificationType.info,
      );

      var success = 0;
      var failed = 0;
      for (final rom in toScrape) {
        if (ScreenScraperService.isMetadataScrapingRunning) break;

        final result = await ScreenScraperService.scrapeSingleGame(
          appSystemId: appSystemId,
          romName: rom['filename'].toString(),
          systemFolder: job.systemFolderName,
          romPath: rom['rom_path'].toString(),
          gameName: rom['title_name']?.toString(),
        );
        if (result['success'] == true) {
          success++;
        } else {
          failed++;
        }
      }

      if (success == 0 && failed == 0) return;

      GlobalNotificationService().show(
        id: _notificationId,
        title: 'Auto-scrape complete',
        message:
            '$success scraped, $failed failed for ${system?.realName ?? job.systemFolderName}',
        type: success > 0
            ? GlobalNotificationType.success
            : GlobalNotificationType.info,
      );
    } catch (e, stackTrace) {
      _log.e('Auto-scrape failed for ${job.systemFolderName}: $e');
      _log.e('   StackTrace: $stackTrace');
    }
  }

  void _notifyMissingCredentialsOnce() {
    if (_missingCredsNotified) return;
    _missingCredsNotified = true;
    GlobalNotificationService().show(
      id: _missingCredsNotificationId,
      title: 'Game artwork unavailable',
      message:
          'Sign in to ScreenScraper under Settings → Services to download '
          'box art, screenshots, and descriptions. The OmiSU art pack only '
          'adds system backgrounds.',
      type: GlobalNotificationType.info,
    );
  }

  /// Returns true when auto-scrape may proceed. On Android with Wi‑Fi-only
  /// enabled, requires Wi‑Fi when `connectivity_plus` is available; otherwise
  /// the check is skipped (treated as allowed).
  Future<bool> _isOnWifi() async {
    if (!Platform.isAndroid) return true;
    // connectivity_plus is not bundled — skip until the dependency is added.
    return true;
  }
}
