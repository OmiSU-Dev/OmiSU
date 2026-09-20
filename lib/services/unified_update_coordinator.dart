import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omisu/config/nordi_update_policy.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/services/builtin_player_update_service.dart';
import 'package:omisu/services/global_notification_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/systems_update_service.dart';
import 'package:omisu/services/app_update_availability_service.dart';
import 'package:omisu/widgets/builtin_player_update_dialog.dart';
import 'package:omisu/widgets/systems_update_dialog.dart';
import 'package:omisu/widgets/update_dialog.dart';
import 'package:flutter_localization/flutter_localization.dart';

/// Result of the startup OTA pass (mirrors legacy [AppScreen] sequencing).
class StartupUpdateResult {
  final bool appUpdateAccepted;
  final bool systemsConfigUpdated;

  const StartupUpdateResult({
    this.appUpdateAccepted = false,
    this.systemsConfigUpdated = false,
  });
}

/// Startup and manual OTA checks: built-in player, system JSON, optional APK.
class UnifiedUpdateCoordinator {
  static final _log = LoggerService.instance;

  static bool builtinUpdateNeedsRetry = false;
  static bool _builtinUpdateInFlight = false;

  /// Runs the same pass as cold start when auto-update toggles are enabled.
  static Future<StartupUpdateResult> runStartupPass({
    required BuildContext context,
    required SqliteConfigProvider configProvider,
  }) async {
    if (!Platform.isAndroid) {
      return const StartupUpdateResult();
    }

    final config = configProvider.config;
    final runAppOta =
        config.autoUpdateApp && NordiUpdatePolicy.appGithubOtaEnabled;
    final runBuiltin =
        config.autoUpdateSystems && NordiUpdatePolicy.builtinPlayerOtaEnabled;
    final runSystemsJson =
        config.autoUpdateSystems &&
        NordiUpdatePolicy.systemsJsonGithubOtaEnabled;

    if (!runAppOta && !runBuiltin && !runSystemsJson) {
      return const StartupUpdateResult();
    }

    if (runBuiltin || runAppOta) {
      final appAccepted = await _runBuiltinAndMaybeApp(
        context: context,
        runBuiltin: runBuiltin,
        runAppCheck: runAppOta,
        showBuiltinNotifications: true,
      );
      if (appAccepted) {
        return const StartupUpdateResult(appUpdateAccepted: true);
      }
    }

    var systemsUpdated = false;
    if (runSystemsJson) {
      if (!context.mounted) return const StartupUpdateResult();
      systemsUpdated = await _showSystemsUpdateIfAvailable(
        context,
        configProvider,
      );
    }
    return StartupUpdateResult(systemsConfigUpdated: systemsUpdated);
  }

  /// Manual check from Settings (built-in player; NeoStation OTA only when enabled).
  static Future<void> runManualCheck({
    required BuildContext context,
    required SqliteConfigProvider configProvider,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      final builtinAccepted = await _confirmBuiltinPlayerUpdateIfNeeded(
        context,
      );
      if (builtinAccepted) {
        await _runBuiltinPlayerUpdate(showNotifications: true);
      }
      if (!context.mounted) return;

      if (NordiUpdatePolicy.systemsJsonGithubOtaEnabled) {
        final systemsUpdated = await _showSystemsUpdateIfAvailable(
          context,
          configProvider,
        );
        if (systemsUpdated) {
          await configProvider.scanSystems();
          return;
        }
        if (!context.mounted) return;
      }

      if (NordiUpdatePolicy.appGithubOtaEnabled) {
        final hadAppUpdate = await _showAppUpdateIfAvailable(
          context,
          forceRefresh: true,
        );
        if (hadAppUpdate) return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.updatesUpToDate.getString(context)),
        ),
      );
    } catch (e, st) {
      _log.e(
        'UnifiedUpdateCoordinator: manual check failed',
        error: e,
        stackTrace: st,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.updatesCheckFailed.getString(context)),
        ),
      );
    }
  }

  static Future<void> retryBuiltinPlayerIfNeeded({
    required BuildContext context,
    required SqliteConfigProvider configProvider,
  }) async {
    if (!Platform.isAndroid || _builtinUpdateInFlight) return;
    if (!builtinUpdateNeedsRetry) return;
    if (!configProvider.config.autoUpdateSystems) return;

    await _runBuiltinPlayerUpdate(showNotifications: true);
  }

  static Future<bool> _runBuiltinAndMaybeApp({
    required BuildContext context,
    required bool runBuiltin,
    required bool runAppCheck,
    required bool showBuiltinNotifications,
  }) async {
    if (runBuiltin) {
      await _runBuiltinPlayerUpdate(
        showNotifications: showBuiltinNotifications,
      );
    }
    if (!runAppCheck || !context.mounted) return false;
    return await _showAppUpdateIfAvailable(context);
  }

  static Future<bool> _confirmBuiltinPlayerUpdateIfNeeded(
    BuildContext context,
  ) async {
    try {
      final preview = await BuiltinPlayerUpdateService.checkPreview();
      if (preview == null || !preview.hasAnyUpdate || !context.mounted) {
        return false;
      }
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BuiltinPlayerUpdateDialog(preview: preview),
      );
      return accepted == true;
    } catch (e) {
      _log.w('UnifiedUpdateCoordinator: builtin preview failed: $e');
      return false;
    }
  }

  static Future<bool> _showAppUpdateIfAvailable(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    if (!NordiUpdatePolicy.appGithubOtaEnabled) return false;

    try {
      await AppUpdateAvailabilityService.instance.refresh(
        force: forceRefresh,
      );
      final updateInfo = AppUpdateAvailabilityService.instance.available.value;
      if (updateInfo != null && context.mounted) {
        final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
        return accepted == true;
      }
    } catch (e) {
      _log.e('UnifiedUpdateCoordinator: app update check failed', error: e);
    }
    return false;
  }

  static Future<bool> _showSystemsUpdateIfAvailable(
    BuildContext context,
    SqliteConfigProvider configProvider,
  ) async {
    if (!NordiUpdatePolicy.systemsJsonGithubOtaEnabled) return false;

    try {
      final updateInfo = await SystemsUpdateService.checkForUpdate();
      if (updateInfo == null || !context.mounted) return false;

      final updated = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SystemsUpdateDialog(updateInfo: updateInfo),
      );

      if (updated == true && context.mounted) {
        await configProvider.reloadSystemDefinitions();
        return true;
      }
    } catch (e) {
      _log.e('UnifiedUpdateCoordinator: systems update check failed', error: e);
    }
    return false;
  }

  static Future<void> _runBuiltinPlayerUpdate({
    required bool showNotifications,
  }) async {
    if (!Platform.isAndroid || _builtinUpdateInFlight) return;

    _builtinUpdateInFlight = true;
    const notificationId = 'builtin_player_update';
    final notifications = GlobalNotificationService();

    if (showNotifications) {
      notifications.show(
        id: notificationId,
        title: 'Built-in player',
        message: 'Checking cores and engine for updates…',
        icon: Icons.sports_esports_rounded,
        ongoing: true,
      );
    }

    try {
      final result = await BuiltinPlayerUpdateService.checkAndUpdate(
        silent: false,
      );

      if (result.anyComponentUpdated) {
        final parts = <String>[];
        if (result.coresUpdateComplete) {
          parts.add('cores v${result.coresVersionApplied}');
        }
        if (result.engineUpdateComplete) {
          parts.add('engine v${result.engineVersionApplied}');
        }
        if (showNotifications) {
          notifications.update(
            id: notificationId,
            title: 'Built-in player',
            message: 'Updated ${parts.join(' · ')}',
            type: GlobalNotificationType.success,
          );
        }
        builtinUpdateNeedsRetry =
            result.coresPartialFailure || result.coresCheckFailed;
      } else if (result.coresDownloaded > 0 &&
          result.coresDownloaded < result.coresExpected) {
        builtinUpdateNeedsRetry = true;
        if (showNotifications) {
          notifications.update(
            id: notificationId,
            title: 'Built-in player',
            message:
                'Partial core update (${result.coresDownloaded}/'
                '${result.coresExpected}). Will retry when online.',
            type: GlobalNotificationType.error,
          );
        }
      } else if (result.coresCheckFailed || result.engineUpdateFailed) {
        builtinUpdateNeedsRetry = true;
        if (showNotifications) {
          notifications.update(
            id: notificationId,
            title: 'Built-in player',
            message: 'Update check failed. Will retry when back online.',
            type: GlobalNotificationType.error,
          );
        }
      } else {
        if (showNotifications) {
          notifications.dismiss(notificationId);
        }
        builtinUpdateNeedsRetry = false;
      }
    } catch (e) {
      _log.e('UnifiedUpdateCoordinator: built-in player update failed', error: e);
      builtinUpdateNeedsRetry = true;
      if (showNotifications) {
        notifications.update(
          id: notificationId,
          title: 'Built-in player',
          message: 'Update check failed. Will retry when back online.',
          type: GlobalNotificationType.error,
        );
      }
    } finally {
      _builtinUpdateInFlight = false;
    }
  }
}
