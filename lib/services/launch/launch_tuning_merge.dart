import 'package:omisu/services/launch/launch_tuning.dart';

/// Merges automatic launch tuning with per-game libretro variable overrides.
LaunchTuning mergeLaunchTuning({
  required LaunchTuning base,
  Map<String, String> perGameCoreVariables = const {},
}) {
  if (perGameCoreVariables.isEmpty) return base;
  return LaunchTuning(
    profileId: base.profileId,
    skipDuplicateFrames: base.skipDuplicateFrames,
    preferLowLatencyAudio: base.preferLowLatencyAudio,
    rumbleEventsEnabled: base.rumbleEventsEnabled,
    coreVariables: {...base.coreVariables, ...perGameCoreVariables},
    corePreferenceKeyword: base.corePreferenceKeyword,
  );
}
