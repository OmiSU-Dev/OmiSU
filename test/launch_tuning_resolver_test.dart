import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/models/core_emulator_model.dart';
import 'package:omisu/services/launch/device_profile.dart';
import 'package:omisu/services/launch/device_profile_service.dart';
import 'package:omisu/services/launch/launch_tuning_resolver.dart';

void main() {
  const nordN30 = DeviceProfile(
    id: 'nord_n30',
    model: 'CPH2583',
    manufacturer: 'OnePlus',
    ramGb: 8,
    tier: DevicePerformanceTier.mid,
    isKnownTarget: true,
  );

  test('Nord N30 NES tuning enables skip-duplicate and low sound quality', () {
    final tuning = LaunchTuningResolver.resolve(
      device: nordN30,
      systemFolder: 'nes',
    );
    expect(tuning.skipDuplicateFrames, isTrue);
    expect(tuning.coreVariables['fceumm_sndquality'], 'Low');
  });

  test('mid-tier SNES prefers performance core keyword', () {
    final tuning = LaunchTuningResolver.resolve(
      device: nordN30,
      systemFolder: 'snes',
    );
    expect(tuning.corePreferenceKeyword, 'performance');
  });

  test('pickTunedEmulator prefers performance core on mid-tier', () {
    final tuning = LaunchTuningResolver.resolve(
      device: nordN30,
      systemFolder: 'snes',
    );
    final candidates = [
      CoreEmulatorModel(
        uniqueId: 'snes.ra64.bsnes2014',
        osId: 2,
        systemId: 'snes',
        name: 'bsnes',
        isInstalled: true,
        isStandalone: false,
        isDefault: true,
        isretroAchievementsCompatible: true,
      ),
      CoreEmulatorModel(
        uniqueId: 'snes.ra64.bsnes2014_performance',
        osId: 2,
        systemId: 'snes',
        name: 'bsnes performance',
        isInstalled: true,
        isStandalone: false,
        isDefault: false,
        isretroAchievementsCompatible: true,
      ),
    ];

    final picked = LaunchTuningResolver.pickTunedEmulator(
      candidates: candidates,
      tuning: tuning,
      configuredDefault: candidates.first,
    );

    expect(picked?.uniqueId, contains('performance'));
  });

  test('simulated Nord N30 differs from desktop high tier', () {
    DeviceProfileService.instance.simulateProfile(DeviceProfileService.nordN30);
    final nordTuning = LaunchTuningResolver.resolve(
      device: DeviceProfileService.instance.profile,
      systemFolder: 'nes',
    );
    DeviceProfileService.instance.simulateProfile(null);

    const desktopHigh = DeviceProfile(
      id: 'desktop_high',
      model: 'linux',
      manufacturer: 'desktop',
      ramGb: 32,
      tier: DevicePerformanceTier.high,
    );
    final highTuning = LaunchTuningResolver.resolve(
      device: desktopHigh,
      systemFolder: 'nes',
    );

    expect(nordTuning.coreVariables['fceumm_sndquality'], 'Low');
    expect(highTuning.coreVariables.isEmpty, isTrue);
    expect(nordTuning.skipDuplicateFrames, isTrue);
    expect(highTuning.skipDuplicateFrames, isFalse);
  });
}
