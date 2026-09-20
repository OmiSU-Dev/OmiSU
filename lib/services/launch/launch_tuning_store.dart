import 'package:omisu/services/launch/launch_tuning.dart';

/// Remembers the most recent launch-time tuning so Settings → Playback can
/// show what was applied. In-memory only (resets on app restart).
class LaunchTuningStore {
  LaunchTuningStore._();

  static final LaunchTuningStore instance = LaunchTuningStore._();

  String? _lastSystem;
  String? _lastGame;
  LaunchTuning? _lastTuning;
  String? _lastEmulatorId;

  LaunchTuning? get lastTuning => _lastTuning;
  String? get lastSystem => _lastSystem;
  String? get lastGame => _lastGame;
  String? get lastEmulatorId => _lastEmulatorId;

  bool get hasLastLaunch => _lastTuning != null;

  void record({
    required String systemFolder,
    required String gameName,
    required LaunchTuning tuning,
    String? emulatorId,
  }) {
    _lastSystem = systemFolder;
    _lastGame = gameName;
    _lastTuning = tuning;
    _lastEmulatorId = emulatorId;
  }

  /// One-line summary for the Playback settings panel.
  String summary() {
    final tuning = _lastTuning;
    if (tuning == null) return 'No game launched yet this session.';
    final vars = tuning.coreVariables.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    final buf = StringBuffer()
      ..write('${ _lastSystem ?? "?"}/${_lastGame ?? "?"} · ')
      ..write('profile=${tuning.profileId} · ')
      ..write('skipDup=${tuning.skipDuplicateFrames} · ')
      ..write('lowLat=${tuning.preferLowLatencyAudio}');
    if (tuning.corePreferenceKeyword != null) {
      buf.write(' · corePref=${tuning.corePreferenceKeyword}');
    }
    if (vars.isNotEmpty) buf.write(' · $vars');
    if (_lastEmulatorId != null) buf.write(' · emu=$_lastEmulatorId');
    return buf.toString();
  }
}
