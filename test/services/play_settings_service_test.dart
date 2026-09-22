import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/play_settings_service.dart';
import 'package:omisu/services/launch/device_profile.dart';

void main() {
  test('PlaySettings defaults match Lemuroid-like baseline', () {
    const settings = PlaySettings();
    expect(settings.autosaveOnExit, isTrue);
    expect(settings.shaderFilter, 'auto');
    expect(settings.rumbleEnabled, isTrue);
    expect(settings.touchControlsEnabled, isFalse);
    expect(settings.showFpsCounter, isFalse);
  });

  test('toEmbeddedParams includes shader and autosave keys', () {
    const settings = PlaySettings(
      hdMode: true,
      hdModeQuality: 'high',
      shaderFilter: 'crt',
    );
    final params = settings.toEmbeddedParams();
    expect(params['hdMode'], isTrue);
    expect(params['hdModeQuality'], 'high');
    expect(params['shaderFilter'], 'crt');
    expect(params['autosaveOnExit'], isTrue);
  });

  test('hdModeQuality defaults to medium', () {
    const settings = PlaySettings();
    expect(settings.hdModeQuality, 'medium');
    expect(settings.hdModeQualityLabel, 'Medium');
    expect(settings.adaptiveHdMode, isTrue);
  });

  test('toEmbeddedParams includes adaptiveHdMode', () {
    const settings = PlaySettings(adaptiveHdMode: false);
    expect(settings.toEmbeddedParams()['adaptiveHdMode'], isFalse);
  });

  test('performance mode forces stable launch params', () {
    const settings = PlaySettings(
      performanceMode: true,
      hdMode: true,
      hdModeQuality: 'high',
      shaderFilter: 'crt',
      immersiveMode: true,
    );
    final params = settings.toEmbeddedParams();
    expect(params['performanceMode'], isTrue);
    expect(params['hdMode'], isFalse);
    expect(params['shaderFilter'], 'sharp');
  });

  test('low-RAM device safeguard applies performance at launch', () {
    const settings = PlaySettings(hdMode: true);
    const device = DeviceProfile(
      id: 'test_low',
      model: 'bolton',
      manufacturer: 'ZTE',
      ramGb: 2,
      tier: DevicePerformanceTier.low,
    );
    expect(settings.effectivePerformanceMode(device), isTrue);
    final params = settings.toEmbeddedParams(device: device);
    expect(params['hdMode'], isFalse);
    expect(params['performanceMode'], isTrue);
    expect(params['shaderFilter'], 'auto');
  });
}
