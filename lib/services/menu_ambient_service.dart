import 'dart:async';
import 'dart:io';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:path_provider/path_provider.dart';

/// Soft looping ambient bed for the OmiSU home / library UI.
///
/// Inspired by handheld "menu presence" (iiSU / DS-era feel) but uses an
/// **original** synthesized pad — never Nintendo system audio.
///
/// Shares the SoLoud engine with [SfxService]. Pauses automatically when a
/// game session starts or when SFX are disabled.
class MenuAmbientService {
  MenuAmbientService._();
  static final MenuAmbientService instance = MenuAmbientService._();

  static const String _assetPath = 'assets/sounds/menu_ambient.wav';
  static const double _defaultVolume = 0.28;

  final _log = LoggerService.instance;

  AudioSource? _source;
  SoundHandle? _handle;
  bool _enabled = true;
  bool _pausedForGame = false;
  bool _loading = false;
  double _volume = _defaultVolume;

  bool get isEnabled => _enabled;
  double get volume => _volume;
  bool get isPlaying => _handle != null;
  bool get isPausedForGame => _pausedForGame;

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      unawaited(stop());
    } else if (!_pausedForGame) {
      unawaited(start());
    }
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    final handle = _handle;
    if (handle != null && SoLoud.instance.isInitialized) {
      SoLoud.instance.setVolume(handle, _volume);
    }
  }

  /// Starts (or resumes) the looping menu bed.
  Future<void> start() async {
    if (!_enabled || _pausedForGame) return;
    if (!SfxService.isScreenOn()) return;
    if (_handle != null) return;
    if (_loading) return;

    _loading = true;
    try {
      if (!SoLoud.instance.isInitialized) {
        try {
          final tempDir = await getTemporaryDirectory();
          await Directory(
            '${tempDir.path}/SoLoudLoader-Temp-Files',
          ).create(recursive: true);
        } catch (_) {}
        await SoLoud.instance.init();
      }

      _source ??= await SoLoud.instance.loadAsset(_assetPath);
      _handle = SoLoud.instance.play(
        _source!,
        volume: _volume,
        looping: true,
      );
      _log.i('[MenuAmbient] Playing menu bed');
    } catch (e) {
      _log.w('[MenuAmbient] Failed to start: $e');
      _handle = null;
    } finally {
      _loading = false;
    }
  }

  Future<void> stop() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.stop(handle);
      }
    } catch (e) {
      _log.w('[MenuAmbient] stop error: $e');
    }
  }

  /// Call when launching an embedded or external game.
  Future<void> pauseForGame() async {
    _pausedForGame = true;
    await stop();
  }

  /// Call when returning from a game session.
  Future<void> resumeAfterGame() async {
    _pausedForGame = false;
    await start();
  }

  /// Screen-off / app background — release the stream so the device can sleep.
  Future<void> appPaused() async {
    await stop();
  }

  Future<void> appResumed() async {
    if (!_pausedForGame) {
      await start();
    }
  }
}
