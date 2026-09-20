import 'dart:async';
import 'dart:io';

import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/constants/recent_card_sizes.dart';
import 'package:omisu/models/gamepad_shoulder_style.dart';
import 'package:omisu/providers/neo_assets_provider.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/services/embedded/play_settings_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/utils/nav_tabs.dart';
import 'package:omisu/widgets/permission_check_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NordiBootstrapService {
  NordiBootstrapService._();

  static final _log = LoggerService.instance;

  static Future<void> applyIfNeeded({
    required SqliteConfigProvider configProvider,
  }) async {
    if (!NordiConfig.curatedBuild || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PermissionCheckWrapper.setupCompletedKey, true);

    if (prefs.getBool(NordiConfig.prefsBootstrapDone) == true) {
      return;
    }

    _log.i('[Nordi] Applying curated bootstrap defaults');

    await configProvider.completeSetup();
    await configProvider.updateAutoUpdateApp(false);
    await configProvider.updateAutoUpdateSystems(false);
    await configProvider.updateSystemGridColumns('S');
    await configProvider.updateRecentCardSize(RecentCardSizes.twoByOne);
    await configProvider.updateGamepadShoulderStyle(
      GamepadShoulderStyle.triggers,
    );

    for (final tab in [
      NavTab.sync,
      NavTab.scraper,
      NavTab.romm,
      NavTab.achievements,
    ]) {
      await configProvider.updateNavTabHidden(tab, true);
    }

    final romRoot = NordiConfig.defaultRomRoot;
    if (configProvider.config.romFolders.isEmpty) {
      await configProvider.addRomFolder(romRoot, scan: true);
    } else if (!configProvider.config.romFolders.contains(romRoot)) {
      await configProvider.addRomFolder(romRoot, scan: true);
    }

    await PlaySettingsService.load();
    await PlaySettingsService.save(
      PlaySettingsService.current.copyWith(
        hdMode: true,
        hdModeQuality: 'medium',
        adaptiveHdMode: true,
        immersiveMode: true,
        rumbleEnabled: true,
      ),
    );

    await prefs.setBool(NordiConfig.prefsBootstrapDone, true);
    _log.i('[Nordi] Bootstrap complete');
  }

  /// One-time: turn off bootstrap-era touch overlay unless the user chose it in Settings.
  static Future<void> applyTouchControlsOffByDefault() async {
    if (!NordiConfig.curatedBuild || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    const migrationKey = 'nordi_touch_off_by_default_v1';
    if (prefs.getBool(migrationKey) == true) return;

    await PlaySettingsService.load();
    if (!await PlaySettingsService.isTouchControlsUserConfigured()) {
      await PlaySettingsService.save(
        PlaySettingsService.current.copyWith(touchControlsEnabled: false),
      );
    }
    await prefs.setBool(migrationKey, true);
  }

  /// One-time (or after upgrade) ensure the curated default ROM folder exists.
  static Future<void> ensureDefaultRomFolder({
    required SqliteConfigProvider configProvider,
  }) async {
    if (!NordiConfig.curatedBuild || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(NordiConfig.prefsDefaultRomFolderEnsured) == true) {
      return;
    }

    final romRoot = NordiConfig.defaultRomRoot;
    final folders = configProvider.config.romFolders;
    if (!folders.contains(romRoot)) {
      _log.i('[Nordi] Adding default ROM folder: $romRoot');
      await configProvider.addRomFolder(romRoot, scan: true);
    }

    await prefs.setBool(NordiConfig.prefsDefaultRomFolderEnsured, true);
  }

  /// Downloads default System Art once systems are known (after startup scan).
  static Future<void> ensureDefaultSystemArt({
    required SqliteConfigProvider configProvider,
    required NeoAssetsProvider neoAssets,
  }) async {
    if (!NordiConfig.curatedBuild || neoAssets.hasActiveTheme) return;

    final systemFolders = configProvider.availableSystems
        .where((s) => s.folderName != 'all-background')
        .map((s) => s.folderName)
        .toList();
    if (systemFolders.isEmpty) return;

    _log.i('[Nordi] Applying default System Art theme');
    unawaited(
      neoAssets.downloadAndApplyTheme(
        NordiConfig.defaultSystemArtThemeFolder,
        systemFolders,
      ),
    );
  }
}
