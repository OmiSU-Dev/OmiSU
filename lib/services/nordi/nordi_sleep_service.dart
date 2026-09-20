import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/menu_ambient_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Puts Nordi in a low-power idle: pause UI audio and request display off.
class NordiSleepService {
  NordiSleepService._();

  static const _channel = MethodChannel('com.omisu.launcher/launcher');
  static const _events = EventChannel('com.omisu.launcher/launcher_events');
  static final _log = LoggerService.instance;

  static bool _sleeping = false;
  static StreamSubscription<dynamic>? _wakeSub;
  static void Function()? onWakeFromDeviceSleep;

  static bool get isSleeping => _sleeping;

  static void _ensureWakeEventListener() {
    _wakeSub ??= _events.receiveBroadcastStream().listen((event) {
      if (event != 'wakeFromSleep' || !_sleeping) return;
      unawaited(_completeWakeFromNative());
    });
  }

  static Future<void> _completeWakeFromNative() async {
    if (!Platform.isAndroid || !_sleeping) return;
    try {
      await MenuAmbientService.instance.appResumed();
    } catch (e) {
      _log.w('[Nordi] wake ambient restore: $e');
    } finally {
      _sleeping = false;
      onWakeFromDeviceSleep?.call();
    }
  }

  static Future<void> enterSleep() async {
    if (!Platform.isAndroid) return;
    _ensureWakeEventListener();
    _sleeping = true;
    try {
      await WakelockPlus.disable();
      await MenuAmbientService.instance.appPaused();
      await _channel.invokeMethod<void>('enterDeviceSleep');
      _log.i('[Nordi] Entered device sleep');
    } catch (e) {
      _log.w('[Nordi] enterSleep: $e');
    }
  }

  static Future<void> wake() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('restoreFromDeviceSleep');
      await MenuAmbientService.instance.appResumed();
    } catch (e) {
      _log.w('[Nordi] wake: $e');
    } finally {
      _sleeping = false;
    }
  }
}
