import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/embedded_core_option_presentation.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';

void main() {
  group('parseLibretroOptionDescription', () {
    test('parses name and pipe-separated values', () {
      final parsed = parseLibretroOptionDescription(
        'GB Link Mode; disabled|Network Server|Network Client',
      );
      expect(parsed.name, 'GB Link Mode');
      expect(
        parsed.values,
        ['disabled', 'Network Server', 'Network Client'],
      );
    });

    test('falls back to values-only list', () {
      final parsed = parseLibretroOptionDescription('enabled|disabled');
      expect(parsed.name, isNull);
      expect(parsed.values, ['enabled', 'disabled']);
    });
  });

  group('EmbeddedCoreVariable', () {
    test('uses libretro display name instead of raw key', () {
      const variable = EmbeddedCoreVariable(
        key: 'gambatte_gb_link_mode',
        value: 'network server',
        description: 'GB Link Mode; disabled|Network Server|Network Client',
      );

      expect(variable.label, 'GB Link Mode');
      expect(
        variable.selectableValues,
        ['disabled', 'Network Server', 'Network Client'],
      );
      expect(variable.presentation.currentValue, 'Network Server');
    });

    test('humanizes raw key when description has no name', () {
      const variable = EmbeddedCoreVariable(
        key: 'gambatte_gb_link_network_server',
        value: 'enabled',
        description: 'enabled|disabled',
      );

      expect(variable.label, 'GB Link Network Server');
      expect(variable.presentation.currentValue, 'On');
      expect(
        variable.presentation.hint,
        'How this device connects for link cable play.',
      );
    });
  });
}
