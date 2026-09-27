import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omisu/config/nordi_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dev / sideload escape hatch when Nordi is not flashed as the retail HOME launcher.
class NordiSafeModeService {
  NordiSafeModeService._();

  static const _prefsKey = 'nordi_safe_mode';
  static const _launcherChannel = MethodChannel('com.omisu.launcher/launcher');

  static bool _enabled = false;

  /// When true, Nordi stops behaving like a locked retail handheld launcher.
  static bool get isEnabled => _enabled;

  static final ValueNotifier<bool> notifier = ValueNotifier(false);

  static Future<void> load() async {
    if (!NordiConfig.curatedBuild) {
      _enabled = false;
      notifier.value = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? false;
    notifier.value = _enabled;
    await _syncNative(_enabled);
  }

  static Future<void> setEnabled(bool value) async {
    if (!NordiConfig.curatedBuild) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    _enabled = value;
    notifier.value = value;
    await _syncNative(value);
    if (value) {
      await _openHomeAppSettingsForEscape();
    }
  }

  /// Opens Android Home app settings so the user can pick the stock launcher.
  static Future<void> _openHomeAppSettingsForEscape() async {
    if (!Platform.isAndroid) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    try {
      await _launcherChannel.invokeMethod<void>('openLauncherSettings');
    } catch (_) {
      try {
        await _launcherChannel.invokeMethod<void>('openDefaultAppsSettings');
      } catch (_) {}
    }
  }

  static Future<void> _syncNative(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _launcherChannel.invokeMethod<void>('setNordiSafeMode', enabled);
    } catch (_) {}
  }
}
