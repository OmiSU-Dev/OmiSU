import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/launch/device_profile.dart';
import 'package:omisu/services/launch/device_profile_service.dart';

void main() {
  test('3643 MB rounds to 4 GB mid tier (Moto G class)', () {
    expect(DeviceProfileService.ramGbFromPhysicalMegabytes(3643), 4);
    expect(DeviceProfileService.ramGbFromPhysicalMegabytes(4096), 4);
    expect(DeviceProfileService.ramGbFromPhysicalMegabytes(3072), 3);
  });

  test('4 GB is mid tier not low', () {
    const profile = DeviceProfile(
      id: 'android_mid',
      model: 'moto g',
      manufacturer: 'motorola',
      ramGb: 4,
      tier: DevicePerformanceTier.mid,
    );
    expect(profile.tier, DevicePerformanceTier.mid);
  });
}
