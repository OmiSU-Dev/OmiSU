import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/services/logger_service.dart';

/// After the display is off, attempts USB gamepad suspend (root/sysfs) and blocks
/// pad input until HOME / PS / Start on the controller.
class ControllerIdleSleepService {
  ControllerIdleSleepService._();

  static const _channel = MethodChannel('com.omisu.launcher/launcher');
  static final _log = LoggerService.instance;

  static const idleMinuteOptions = <int>[0, 1, 3, 5, 10, 15];

  static bool hostSleepActive = false;
  static bool lastUsbCut = false;
  static void Function(bool active, bool usbCut)? onHostSleepChanged;

  static void handleHostSleepEvent(Map<dynamic, dynamic> event) {
    hostSleepActive = event['active'] == true;
    lastUsbCut = event['usbCut'] == true;
    _log.i(
      '[ControllerIdle] hostSleep=$hostSleepActive usbCut=$lastUsbCut',
    );
    onHostSleepChanged?.call(hostSleepActive, lastUsbCut);
  }

  static Future<int> getIdleMinutes() async {
    if (!Platform.isAndroid) return 0;
    try {
      final v =
          await _channel.invokeMethod<int>('getControllerIdleSleepMinutes');
      return v ?? 5;
    } catch (e) {
      _log.w('[ControllerIdle] getIdleMinutes: $e');
      return 5;
    }
  }

  static Future<void> setIdleMinutes(int minutes) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'setControllerIdleSleepMinutes',
        {'minutes': minutes},
      );
    } catch (e) {
      _log.w('[ControllerIdle] setIdleMinutes: $e');
    }
  }

  static Future<bool> getSuspendOnNordiSleep() async {
    if (!Platform.isAndroid) return false;
    try {
      final v =
          await _channel.invokeMethod<bool>('getControllerSuspendOnNordiSleep');
      return v ?? false;
    } catch (e) {
      _log.w('[ControllerIdle] getSuspendOnNordiSleep: $e');
      return false;
    }
  }

  static Future<void> setSuspendOnNordiSleep(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'setControllerSuspendOnNordiSleep',
        {'enabled': enabled},
      );
    } catch (e) {
      _log.w('[ControllerIdle] setSuspendOnNordiSleep: $e');
    }
  }

  static int nextOption(int current) {
    final i = idleMinuteOptions.indexOf(current);
    if (i < 0) return idleMinuteOptions[3];
    return idleMinuteOptions[(i + 1) % idleMinuteOptions.length];
  }
}
