import 'package:omisu/models/core_emulator_model.dart';
import 'package:omisu/services/launch/device_profile.dart';
import 'package:omisu/services/launch/launch_tuning.dart';

/// Picks launch-time emulator settings from device tier + system + game context.
///
/// Curated tables ship with OmiSU; user overrides (per-system emulator choice)
/// still win in [pickTunedEmulator].
class LaunchTuningResolver {
  LaunchTuningResolver._();

  static LaunchTuning resolve({
    required DeviceProfile device,
    required String systemFolder,
    String? coreName,
  }) {
    final base = _baseForTier(device);
    final systemVars = _coreVariablesForSystem(systemFolder, device.tier);
    final keyword = _coreKeywordForSystem(systemFolder, device.tier);

    return LaunchTuning(
      profileId: device.id,
      skipDuplicateFrames: base.skipDuplicateFrames,
      preferLowLatencyAudio: base.preferLowLatencyAudio,
      rumbleEventsEnabled: base.rumbleEventsEnabled,
      coreVariables: {...base.coreVariables, ...systemVars},
      corePreferenceKeyword: keyword,
    );
  }

  /// Among [candidates], pick the best installed emulator for [tuning].
  ///
  /// Explicit [userDefault] always wins. Otherwise prefer installed standalones,
  /// then an installed [configuredDefault], then a core matching
  /// [tuning.corePreferenceKeyword], then any installed core, then [configuredDefault].
  static CoreEmulatorModel? pickTunedEmulator({
    required List<CoreEmulatorModel> candidates,
    required LaunchTuning tuning,
    CoreEmulatorModel? userDefault,
    CoreEmulatorModel? configuredDefault,
  }) {
    if (userDefault != null) return userDefault;

    bool isInstalledUid(String? uid) {
      if (uid == null) return false;
      for (final e in candidates) {
        if (e.uniqueId == uid && e.isInstalled) return true;
      }
      return false;
    }

    for (final e in candidates) {
      if (e.isInstalled && e.isStandalone) return e;
    }

    final keyword = tuning.corePreferenceKeyword?.toLowerCase();
    if (keyword != null && keyword.isNotEmpty) {
      for (final e in candidates) {
        if (!e.isInstalled) continue;
        if (e.uniqueId.toLowerCase().contains(keyword)) return e;
      }
    }

    if (isInstalledUid(configuredDefault?.uniqueId)) return configuredDefault;

    for (final e in candidates) {
      if (e.isInstalled) return e;
    }
    return configuredDefault;
  }

  static LaunchTuning _baseForTier(DeviceProfile device) {
    return switch (device.tier) {
      DevicePerformanceTier.low => const LaunchTuning(
          profileId: 'low',
          skipDuplicateFrames: true,
          preferLowLatencyAudio: true,
          rumbleEventsEnabled: false,
        ),
      DevicePerformanceTier.mid => const LaunchTuning(
          profileId: 'mid',
          skipDuplicateFrames: true,
          preferLowLatencyAudio: true,
          rumbleEventsEnabled: true,
        ),
      DevicePerformanceTier.high => const LaunchTuning(
          profileId: 'high',
          skipDuplicateFrames: false,
          preferLowLatencyAudio: false,
          rumbleEventsEnabled: true,
        ),
    }.copyWithProfileId(device.id);
  }

  static Map<String, String> _coreVariablesForSystem(
    String systemFolder,
    DevicePerformanceTier tier,
  ) {
    if (systemFolder == 'nes') {
      return switch (tier) {
        DevicePerformanceTier.low => const {
            'fceumm_sndquality': 'Low',
            'fceumm_nospritelimit': 'disabled',
          },
        DevicePerformanceTier.mid => const {
            'fceumm_sndquality': 'Low',
          },
        DevicePerformanceTier.high => const {},
      };
    }
    return const {};
  }

  static String? _coreKeywordForSystem(
    String systemFolder,
    DevicePerformanceTier tier,
  ) {
    if (tier == DevicePerformanceTier.high) return null;

    return switch (systemFolder) {
      'snes' ||
      'sfc' ||
      'snes-hacks' ||
      'sfc-hacks' =>
        'performance',
      'psx' || 'ps1' => 'rearm',
      'n64' => 'parallel',
      'gba' => 'mgba',
      'nds' || 'ds' => 'melonds',
      _ => tier == DevicePerformanceTier.low ? 'fast' : null,
    };
  }
}

extension on LaunchTuning {
  LaunchTuning copyWithProfileId(String id) => LaunchTuning(
        profileId: id,
        skipDuplicateFrames: skipDuplicateFrames,
        preferLowLatencyAudio: preferLowLatencyAudio,
        rumbleEventsEnabled: rumbleEventsEnabled,
        coreVariables: coreVariables,
        corePreferenceKeyword: corePreferenceKeyword,
      );
}
