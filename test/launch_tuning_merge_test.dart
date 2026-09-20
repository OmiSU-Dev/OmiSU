import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/launch/launch_tuning.dart';
import 'package:omisu/services/launch/launch_tuning_merge.dart';

void main() {
  const base = LaunchTuning(
    profileId: 'n30',
    skipDuplicateFrames: true,
    preferLowLatencyAudio: false,
    rumbleEventsEnabled: true,
    coreVariables: {'foo': 'auto', 'bar': '1'},
  );

  test('returns base when per-game map is empty', () {
    final merged = mergeLaunchTuning(base: base);
    expect(merged, base);
  });

  test('per-game variables override base keys', () {
    final merged = mergeLaunchTuning(
      base: base,
      perGameCoreVariables: {'bar': '2', 'baz': 'on'},
    );
    expect(merged.profileId, base.profileId);
    expect(merged.coreVariables, {
      'foo': 'auto',
      'bar': '2',
      'baz': 'on',
    });
  });
}
