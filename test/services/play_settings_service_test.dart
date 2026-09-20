import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/play_settings_service.dart';

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
}
