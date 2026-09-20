import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/menu_ambient_service.dart';
import 'package:omisu/services/music_player_service.dart';
import 'package:omisu/services/sfx_service.dart';

/// Releases the shared SoLoud engine before embedded libretro play.
///
/// External emulators background OmiSU, which tears down SoLoud via
/// [MusicPlayerService.appPaused]. Embedded play keeps the app foregrounded,
/// so we must release the audio device explicitly or LibretroDroid stays silent.
class EmbeddedAudioSession {
  EmbeddedAudioSession._();

  static final _log = LoggerService.instance;
  static bool _active = false;
  static bool _sfxWasEnabled = true;
  static bool _releasedSoLoud = false;

  static Future<void> enter() async {
    if (_active) return;
    _active = true;
    _sfxWasEnabled = SfxService().isEnabled;
    SfxService().setEnabled(false);
    _releasedSoLoud = await MusicPlayerService().releaseEngineForEmbeddedPlay();
    if (!_releasedSoLoud) {
      _releasedSoLoud = _releaseSoLoudIfNeeded();
    }
    await MenuAmbientService.instance.pauseForGame();
  }

  static Future<void> exit() async {
    if (!_active) return;
    _active = false;

    final shouldRestoreEngine = _releasedSoLoud || !SoLoud.instance.isInitialized;
    if (_releasedSoLoud) {
      _releasedSoLoud = false;
    }
    if (shouldRestoreEngine) {
      try {
        await SfxService().reinitializeAfterEngineRestart();
      } catch (e) {
        _log.w('[EmbeddedAudio] SFX reload failed: $e');
      }
      await MusicPlayerService().resumeAfterEmbeddedPlay();
    }

    await MenuAmbientService.instance.resumeAfterGame();
    SfxService().setEnabled(_sfxWasEnabled);
    _sfxWasEnabled = true;
  }

  static bool _releaseSoLoudIfNeeded() {
    if (!SoLoud.instance.isInitialized) return false;
    try {
      SoLoud.instance.deinit();
      SfxService().handleEngineTornDown();
      _log.i('[EmbeddedAudio] Released SoLoud for embedded play');
      return true;
    } catch (e) {
      _log.w('[EmbeddedAudio] SoLoud deinit failed: $e');
      return false;
    }
  }
}
