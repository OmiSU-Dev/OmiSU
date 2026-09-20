import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/services/embedded/embedded_core_option_allowlist.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';

void main() {
  group('embedded core option allowlist', () {
    test('hides gambatte link and network options', () {
      final filtered = filterUserFacingCoreOptions(
        systemFolder: 'gbc',
        variables: const [
          EmbeddedCoreVariable(
            key: 'gambatte_mix_frames',
            value: 'disabled',
            description: 'LCD ghosting; disabled|mix',
          ),
          EmbeddedCoreVariable(
            key: 'gambatte_gb_link_mode',
            value: 'network server',
          ),
          EmbeddedCoreVariable(
            key: 'gambatte_gb_link_network_server',
            value: 'enabled',
          ),
        ],
      );

      expect(filtered.map((v) => v.key), ['gambatte_mix_frames']);
    });

    test('hides psx dynarec even if core reports it', () {
      expect(
        isUserFacingCoreOption(
          systemFolder: 'ps1',
          key: 'pcsx_rearmed_drc',
        ),
        isFalse,
      );
      expect(
        isUserFacingCoreOption(
          systemFolder: 'ps1',
          key: 'pcsx_rearmed_frameskip',
        ),
        isTrue,
      );
    });

    test('hides psp resolution and cpu toggles', () {
      expect(
        isUserFacingCoreOption(
          systemFolder: 'psp',
          key: 'ppsspp_internal_resolution',
        ),
        isFalse,
      );
      expect(
        isUserFacingCoreOption(
          systemFolder: 'psp',
          key: 'ppsspp_cpu_core',
        ),
        isFalse,
      );
    });

    test('systems without curated options show none', () {
      final filtered = filterUserFacingCoreOptions(
        systemFolder: 'snes',
        variables: const [
          EmbeddedCoreVariable(key: 'snes9x_overclock', value: 'enabled'),
        ],
      );
      expect(filtered, isEmpty);
    });
  });
}
