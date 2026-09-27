import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/nordi/nordi_launcher_events.dart';
import 'package:omisu/services/menu_ambient_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// How deeply [enterSleep] managed to rest the device display.
enum NordiSleepDepth {
  /// Panel off via system sleep (priv/platform) or accessibility lock.
  displayOff,

  /// Brightness minimized only; display may stay technically on.
  dimFallback,
}

class NordiSleepEnterResult {
  const NordiSleepEnterResult({
    required this.depth,
    this.nativeMethod,
  });

  final NordiSleepDepth depth;
  final String? nativeMethod;
}

/// Puts Nordi in a low-power idle: pause UI audio and request display off.
class NordiSleepService {
  NordiSleepService._();

  static const _channel = MethodChannel('com.omisu.launcher/launcher');
  static final _log = LoggerService.instance;

  static bool _sleeping = false;
  static NordiSleepDepth? _lastDepth;
  static void Function()? onWakeFromDeviceSleep;

  static bool get isSleeping => _sleeping;
  static NordiSleepDepth? get lastSleepDepth => _lastDepth;

  static void _ensureWakeEventListener() {
    NordiLauncherEvents.ensureListening();
  }

  /// Called from [NordiLauncherEvents] when native emits wakeFromSleep.
  static void handleWakeFromSleepEvent() {
    if (!_sleeping) return;
    unawaited(_completeWakeFromNative());
  }

  static Future<void> _completeWakeFromNative() async {
    if (!Platform.isAndroid || !_sleeping) return;
    try {
      await MenuAmbientService.instance.appResumed();
    } catch (e) {
      _log.w('[Nordi] wake ambient restore: $e');
    } finally {
      _sleeping = false;
      _lastDepth = null;
      onWakeFromDeviceSleep?.call();
    }
  }

  static Future<NordiSleepEnterResult?> enterSleep() async {
    if (!Platform.isAndroid) return null;
    _ensureWakeEventListener();
    _sleeping = true;
    try {
      await WakelockPlus.disable();
      await MenuAmbientService.instance.appPaused();
      final raw = await _channel.invokeMethod<dynamic>('enterDeviceSleep');
      final parsed = _parseEnterResult(raw);
      _lastDepth = parsed.depth;
      _log.i(
        '[Nordi] Entered sleep depth=${parsed.depth.name} '
        'method=${parsed.nativeMethod}',
      );
      return parsed;
    } catch (e) {
      _sleeping = false;
      _lastDepth = null;
      _log.w('[Nordi] enterSleep: $e');
      return null;
    }
  }

  static NordiSleepEnterResult _parseEnterResult(dynamic raw) {
    if (raw is Map) {
      final displayOff = raw['displayOff'] == true;
      final method = raw['method']?.toString();
      return NordiSleepEnterResult(
        depth: displayOff
            ? NordiSleepDepth.displayOff
            : NordiSleepDepth.dimFallback,
        nativeMethod: method,
      );
    }
    // Legacy native success(true) before structured result.
    return const NordiSleepEnterResult(depth: NordiSleepDepth.displayOff);
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
      _lastDepth = null;
    }
  }
}
