import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/config/nordi_update_policy.dart';
import 'package:omisu/services/global_notification_service.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/update_service.dart';

/// Polls GitHub for a newer Nordi APK and drives the header update toast.
class AppUpdateAvailabilityService {
  AppUpdateAvailabilityService._();
  static final AppUpdateAvailabilityService instance =
      AppUpdateAvailabilityService._();

  static const _notificationId = 'app_update_available';
  static const _minCheckInterval = Duration(hours: 6);

  final _log = LoggerService.instance;

  final ValueNotifier<UpdateInfo?> available = ValueNotifier(null);

  /// Bumped when banner visibility changes so [AppUpdateStatusToast] rebuilds.
  final ValueNotifier<int> uiTick = ValueNotifier(0);

  DateTime? _lastCheckAt;
  String? _bannerDismissedForVersion;

  void _notifyUi() {
    uiTick.value++;
  }

  bool get isBannerVisible {
    final info = available.value;
    if (info == null) return false;
    return _bannerDismissedForVersion != info.latestVersion;
  }

  void dismissBanner() {
    final version = available.value?.latestVersion;
    if (version != null) {
      _bannerDismissedForVersion = version;
      _notifyUi();
    }
  }

  /// Queries [UpdateService] and updates [available] plus the notification bell.
  Future<void> refresh({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!NordiUpdatePolicy.appGithubOtaEnabled) return;

    final now = DateTime.now();
    if (!force &&
        _lastCheckAt != null &&
        now.difference(_lastCheckAt!) < _minCheckInterval) {
      return;
    }
    _lastCheckAt = now;

    try {
      final info = await UpdateService.checkForUpdates();
      available.value = info;

      if (info != null) {
        if (_bannerDismissedForVersion != info.latestVersion) {
          _bannerDismissedForVersion = null;
        }
        GlobalNotificationService().show(
          id: _notificationId,
          title: 'Nordi update',
          message: 'Version ${info.latestVersion} is ready to install.',
          icon: Symbols.system_update_alt,
          type: GlobalNotificationType.info,
        );
      } else {
        GlobalNotificationService().dismiss(_notificationId);
      }
      _notifyUi();
    } catch (e) {
      _log.w('AppUpdateAvailabilityService: refresh failed: $e');
    }
  }
}
