import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omisu/services/embedded/embedded_core_option_presentation.dart';

class EmbeddedCoreVariable {
  const EmbeddedCoreVariable({
    required this.key,
    this.value,
    this.description,
  });

  final String key;
  final String? value;
  final String? description;

  List<String> get selectableValues {
    final parsed = parseLibretroOptionDescription(description);
    if (parsed.values.isNotEmpty) {
      return parsed.values;
    }
    final current = value;
    if (current == 'enabled' || current == 'disabled') {
      return const ['enabled', 'disabled'];
    }
    if (current != null && current.isNotEmpty) {
      return [current];
    }
    return const [];
  }

  String get label => presentation.title;

  EmbeddedCoreOptionPresentation get presentation {
    return presentCoreOption(
      key: key,
      value: value,
      description: description,
      selectableValues: selectableValues,
    );
  }
}

class EmbeddedEmulatorService {
  EmbeddedEmulatorService._();

  static const _channel = MethodChannel('com.omisu.launcher/embedded_emulator');
  static const _events =
      EventChannel('com.omisu.launcher/embedded_emulator_events');

  static Stream<dynamic>? _eventStream;

  static Stream<dynamic> get events {
    _eventStream ??= _events.receiveBroadcastStream();
    return _eventStream!;
  }

  static Future<bool> saveState({int slot = 1}) async {
    final result = await _channel.invokeMethod<bool>('saveState', {'slot': slot});
    return result ?? false;
  }

  static Future<bool> loadState({int slot = 1}) async {
    final result = await _channel.invokeMethod<bool>('loadState', {'slot': slot});
    return result ?? false;
  }

  static Future<void> setAudioEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setAudioEnabled', {'enabled': enabled});
  }

  static Future<void> setFastForward(bool enabled) async {
    await _channel.invokeMethod<void>('setFastForward', {'enabled': enabled});
  }

  /// When false, physical gamepad events reach Flutter instead of libretro.
  static Future<void> setRouteGamepadToCore(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setRouteGamepadToCore', {
      'enabled': enabled,
    });
  }

  static Future<bool> isAudioEnabled() async {
    final result = await _channel.invokeMethod<bool>('isAudioEnabled');
    return result ?? true;
  }

  static Future<bool> isFastForward() async {
    final result = await _channel.invokeMethod<bool>('isFastForward');
    return result ?? false;
  }

  static Future<bool> hasStateSlot({required int slot}) async {
    final result = await _channel.invokeMethod<bool>('hasStateSlot', {'slot': slot});
    return result ?? false;
  }

  static Future<Uint8List?> getStatePreview({required int slot}) async {
    final result = await _channel.invokeMethod<Uint8List>('getStatePreview', {
      'slot': slot,
    });
    return result;
  }

  static Future<List<EmbeddedCoreVariable>> getCoreVariables() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getCoreVariables');
    if (result == null) return const [];
    return result.map((entry) {
      final map = Map<String, dynamic>.from(entry as Map);
      return EmbeddedCoreVariable(
        key: map['key']?.toString() ?? '',
        value: map['value']?.toString(),
        description: map['description']?.toString(),
      );
    }).where((v) => v.key.isNotEmpty).toList();
  }

  static Future<bool> updateCoreVariable({
    required String key,
    required String value,
  }) async {
    final result = await _channel.invokeMethod<bool>('updateCoreVariable', {
      'key': key,
      'value': value,
    });
    return result ?? false;
  }

  /// Android [KeyEvent] action constants for touch overlays.
  static const int keyActionDown = 0;
  static const int keyActionUp = 1;
  static const int keyDpadUp = 19;
  static const int keyDpadDown = 20;
  static const int keyDpadLeft = 21;
  static const int keyDpadRight = 22;
  static const int keyButtonA = 96;
  static const int keyButtonB = 97;
  static const int keyButtonX = 99;
  static const int keyButtonY = 100;
  static const int keyButtonL1 = 102;
  static const int keyButtonR1 = 103;
  static const int keyButtonL2 = 104;
  static const int keyButtonR2 = 105;
  static const int keyButtonStart = 108;
  static const int keyButtonSelect = 109;

  static Future<void> reset() async {
    await _channel.invokeMethod<void>('reset');
  }

  static Future<void> unload() async {
    await _channel.invokeMethod<void>('unload');
  }

  /// Waits until the native LibretroDroid session is fully torn down.
  static Future<void> ensureCoreIdle() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('ensureCoreIdle');
  }

  static Future<void> setFpsCounterEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setFpsCounterEnabled', {
      'enabled': enabled,
    });
  }

  static Future<void> applyDisplaySettings({
    required String systemId,
    required bool hdMode,
    required String shaderFilter,
    String hdModeQuality = 'medium',
    bool adaptiveHdMode = true,
  }) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('applyDisplaySettings', {
      'systemId': systemId,
      'hdMode': hdMode,
      'hdModeQuality': hdModeQuality,
      'adaptiveHdMode': adaptiveHdMode,
      'shaderFilter': shaderFilter,
    });
  }

  static Future<bool> hasPhysicalGamepad() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>('hasPhysicalGamepad');
    return result ?? false;
  }

  static Future<void> sendKeyEvent({
    required int action,
    required int keyCode,
    int port = 0,
  }) async {
    await _channel.invokeMethod<void>('sendKeyEvent', {
      'action': action,
      'keyCode': keyCode,
      'port': port,
    });
  }

  /// Sends RetroPad Start to the core (bypasses [setRouteGamepadToCore]).
  /// Use when the physical Start key opens the pause menu instead of the game.
  static Future<void> tapStartButton({int port = 0}) async {
    if (!Platform.isAndroid) return;
    await sendKeyEvent(
      action: keyActionDown,
      keyCode: keyButtonStart,
      port: port,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sendKeyEvent(
      action: keyActionUp,
      keyCode: keyButtonStart,
      port: port,
    );
  }

  static Future<String> getBuiltinCoresVersion() async {
    final result = await _channel.invokeMethod<String>('getBuiltinCoresVersion');
    return result ?? '1.17.0';
  }

  static Future<String> getBundledLibretroDroidVersion() async {
    final result =
        await _channel.invokeMethod<String>('getBundledLibretroDroidVersion');
    return result ?? '0.13.2';
  }

  static Future<bool> downloadLibretroDroidEngine(String version) async {
    final result = await _channel.invokeMethod<bool>(
      'downloadLibretroDroidEngine',
      {'version': version},
    );
    return result ?? false;
  }

  static Future<int> downloadAllBuiltinCores(String version) async {
    final result = await _channel.invokeMethod<int>('downloadAllBuiltinCores', {
      'version': version,
    });
    return result ?? 0;
  }

  static Future<void> setBuiltinCoresVersion(String version) async {
    await _channel.invokeMethod<void>('setBuiltinCoresVersion', {
      'version': version,
    });
  }

  /// Ensures the libretro core for [systemFolderName] exists on disk before the
  /// embedded PlatformView is created. Downloads from LemuroidCores when needed.
  ///
  /// When [romPath] is set, PPSSPP system assets and large SAF ROM copies are
  /// also prepared on a background thread (important for PSP ISO/CSO).
  static Future<void> ensureCoreReady(
    String systemFolderName, {
    String? romPath,
  }) async {
    await _channel.invokeMethod<void>('ensureCoreReady', {
      'systemId': systemFolderName,
      if (romPath != null && romPath.isNotEmpty) 'romPath': romPath,
    });
  }
}
