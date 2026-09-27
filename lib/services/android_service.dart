import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/services/logger_service.dart';
import '../screens/external_play_pre_launch_screen.dart';

/// Service responsible for interacting with the Android operating system via MethodChannels.
///
/// Handles app discovery, package launching, and retrieving native assets
/// like application icons.
class AndroidService {
  /// The primary communication channel for Android-specific game operations.
  static const MethodChannel _channel = MethodChannel(
    'com.omisu.launcher/game',
  );

  static final _log = LoggerService.instance;

  /// Retrieves a list of all installed applications on the device.
  ///
  /// Returns a list of maps containing app metadata (label, package name, etc.).
  /// The [includeSystemApps] flag determines if system-provided apps should be returned.
  static Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeSystemApps = false,
  }) async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod(
        'getInstalledApps',
        {'includeSystemApps': includeSystemApps},
      );

      return apps.map((dynamic item) {
        final Map<Object?, Object?> map = item as Map<Object?, Object?>;
        return map.map((key, value) => MapEntry(key.toString(), value));
      }).toList();
    } on PlatformException catch (e) {
      _log.e("Failed to get installed apps: '${e.message}'.");
      return [];
    }
  }

  /// Attempts to launch an Android application using its unique [packageName].
  ///
  /// When [gameSession] is true, marks an OmiSU play session (recent play,
  /// return detection, controller Start → stream menu).
  static Future<void> prepareExternalPlayStreaming({String packageName = ''}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('prepareExternalPlayStreaming', {
        'packageName': packageName,
      });
    } on PlatformException catch (e) {
      _log.w("prepareExternalPlayStreaming: '${e.message}'.");
    }
  }

  static Future<bool> launchPackage(
    String packageName, {
    bool gameSession = false,
    String gameTitle = '',
    bool startStreamAfterLaunch = false,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('launchPackage', {
        'packageName': packageName,
        'gameSession': gameSession,
        'gameTitle': gameTitle,
        'startStreamAfterLaunch': startStreamAfterLaunch,
      });
      return result;
    } on PlatformException catch (e) {
      _log.e("Failed to launch package: '${e.message}'.");
      return false;
    }
  }

  static Future<void> endExternalPlaySession() async {
    try {
      await _channel.invokeMethod('endExternalPlaySession');
    } on PlatformException catch (e) {
      _log.e("endExternalPlaySession: '${e.message}'.");
    }
  }

  static Future<bool> isExternalPlayMenuVisible() async {
    if (ExternalPlayPreLaunchFlow.isShowing) return true;
    try {
      final result = await _channel.invokeMethod<bool>('isExternalPlayMenuVisible');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Extracts the launcher icon of an application as a [Uint8List] (PNG format).
  ///
  /// Returns null if the icon cannot be retrieved or the package is missing.
  static Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final Uint8List? iconData = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      return iconData;
    } on PlatformException catch (e) {
      _log.e("Failed to get app icon: '${e.message}'.");
      return null;
    }
  }

  /// Verifies whether an application with the given [packageName] is currently installed.
  static Future<bool> isPackageInstalled(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('isPackageInstalled', {
        'packageName': packageName,
      });
      return result;
    } on PlatformException catch (e) {
      _log.e("Failed to check if package is installed: '${e.message}'.");
      return false;
    }
  }
}
