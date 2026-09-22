import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/models/embedded_core_config.dart';

void main() {
  group('EmbeddedCoreRegistry', () {
    test('ps1 folder maps to pcsx_rearmed core', () {
      expect(EmbeddedCoreRegistry.supports('ps1'), isTrue);
      expect(
        EmbeddedCoreRegistry.configFor('ps1')!.coreFileName,
        'libpcsx_rearmed_libretro_android.so',
      );
      expect(
        EmbeddedCoreRegistry.configFor('ps1')!.coreName,
        'pcsx_rearmed',
      );
    });

    test('genesis alias maps to genesis_plus_gx', () {
      expect(EmbeddedCoreRegistry.supports('genesis'), isTrue);
      final config = EmbeddedCoreRegistry.configFor('genesis')!;
      expect(config.coreName, 'genesis_plus_gx');
      expect(config.systemId, 'genesis');
    });

    test('fc alias maps to fceumm with fc system id', () {
      expect(EmbeddedCoreRegistry.supports('fc'), isTrue);
      final config = EmbeddedCoreRegistry.configFor('fc')!;
      expect(config.coreName, 'fceumm');
      expect(config.systemId, 'fc');
    });

    test('ds alias maps to melonds and keeps the ds system id', () {
      expect(EmbeddedCoreRegistry.supports('ds'), isTrue);
      expect(EmbeddedCoreRegistry.supports('nds'), isTrue);
      final config = EmbeddedCoreRegistry.configFor('ds')!;
      expect(config.coreName, 'melonds');
      expect(config.coreFileName, 'libmelonds_libretro_android.so');
      expect(config.systemId, 'ds');
    });

    test('2600 folder maps to stella core', () {
      expect(EmbeddedCoreRegistry.supports('2600'), isTrue);
      expect(EmbeddedCoreRegistry.configFor('2600')!.coreName, 'stella');
    });

    test('uniqueCores lists all libretro cores once', () {
      final cores = EmbeddedCoreRegistry.uniqueCores;
      expect(cores.length, 19);
      expect(cores.map((c) => c.coreName).toSet().length, 19);
    });

    test('unsupported system returns false', () {
      expect(EmbeddedCoreRegistry.supports('switch'), isFalse);
      expect(EmbeddedCoreRegistry.configFor('switch'), isNull);
    });
  });
}
