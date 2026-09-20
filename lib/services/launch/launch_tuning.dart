/// Runtime emulator settings chosen for a specific device + game launch.
class LaunchTuning {
  const LaunchTuning({
    required this.profileId,
    required this.skipDuplicateFrames,
    required this.preferLowLatencyAudio,
    required this.rumbleEventsEnabled,
    this.coreVariables = const {},
    this.corePreferenceKeyword,
  });

  final String profileId;
  final bool skipDuplicateFrames;
  final bool preferLowLatencyAudio;
  final bool rumbleEventsEnabled;

  /// Libretro core option key/value pairs applied before the core loads.
  final Map<String, String> coreVariables;

  /// When auto-picking a RetroArch core, prefer a uniqueId containing this token
  /// (e.g. `performance`, `fast`, `rearm`).
  final String? corePreferenceKeyword;

  Map<String, dynamic> toEmbeddedParams() => {
        'skipDuplicateFrames': skipDuplicateFrames,
        'preferLowLatencyAudio': preferLowLatencyAudio,
        'rumbleEventsEnabled': rumbleEventsEnabled,
        'variables': coreVariables,
      };

  Map<String, dynamic> toEmbeddedParamsWithPlay(Map<String, dynamic> play) => {
        ...toEmbeddedParams(),
        ...play,
      };
}
