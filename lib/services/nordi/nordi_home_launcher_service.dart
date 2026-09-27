import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/services/nordi/nordi_safe_mode_service.dart';

/// Keeps Nordi as the default Android HOME app in retail (non–safe mode) builds.
class NordiHomeLauncherService {
  NordiHomeLauncherService._();

  static const _channel = MethodChannel('com.omisu.launcher/launcher');

  static DateTime? _lastPromoteAttempt;

  static bool _retailPolicyActive() =>
      NordiConfig.curatedBuild && !NordiSafeModeService.isEnabled;

  static Future<bool> isDefaultHome() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system Home role UI or Home app settings (user confirmation required on retail).
  static Future<bool> requestDefaultHome() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestDefaultHome') ?? false;
      if (result) return true;
      return await isDefaultHome();
    } on PlatformException {
      return await isDefaultHome();
    }
  }

  /// Wi‑Fi deploy / priv-app can set HOME via adb. Users change HOME in Settings or Safe mode.
  /// Intentionally does not run on cold boot or resume (see main.dart) — opening the Home
  /// role UI during startup races Flutter and breaks app-drawer launches after stock HOME.
  static Future<void> promoteRetailHomeIfNeeded() async {
    if (!Platform.isAndroid || !_retailPolicyActive()) return;
    if (await isDefaultHome()) return;

    final now = DateTime.now();
    if (_lastPromoteAttempt != null &&
        now.difference(_lastPromoteAttempt!) < const Duration(seconds: 60)) {
      return;
    }
    _lastPromoteAttempt = now;
    await requestDefaultHome();
  }
}
