import 'embedded_system_aliases.dart';

class EmbeddedCoreConfig {
  final String systemId;
  final String coreName;
  final String coreFileName;
  final List<String> extensions;

  const EmbeddedCoreConfig({
    required this.systemId,
    required this.coreName,
    required this.coreFileName,
    required this.extensions,
  });
}

/// Registry of libretro cores for in-app (embedded) play on Android.
///
/// Covers the full Lemuroid system list (~25), with OmiSU folder aliases
/// (e.g. ps1, ngpc, mame, genesis) resolved via [EmbeddedSystemAliases].
class EmbeddedCoreRegistry {
  EmbeddedCoreRegistry._();

  static const _canonicalConfigs = <String, EmbeddedCoreConfig>{
    'nes': EmbeddedCoreConfig(
      systemId: 'nes',
      coreName: 'fceumm',
      coreFileName: 'libfceumm_libretro_android.so',
      extensions: ['nes', 'fds', 'unf', 'unif'],
    ),
    'snes': EmbeddedCoreConfig(
      systemId: 'snes',
      coreName: 'snes9x',
      coreFileName: 'libsnes9x_libretro_android.so',
      extensions: ['smc', 'sfc', 'swc', 'fig'],
    ),
    'md': EmbeddedCoreConfig(
      systemId: 'md',
      coreName: 'genesis_plus_gx',
      coreFileName: 'libgenesis_plus_gx_libretro_android.so',
      extensions: ['md', 'smd', 'gen', 'bin', 'sg'],
    ),
    'gb': EmbeddedCoreConfig(
      systemId: 'gb',
      coreName: 'gambatte',
      coreFileName: 'libgambatte_libretro_android.so',
      extensions: ['gb'],
    ),
    'gbc': EmbeddedCoreConfig(
      systemId: 'gbc',
      coreName: 'gambatte',
      coreFileName: 'libgambatte_libretro_android.so',
      extensions: ['gbc'],
    ),
    'gba': EmbeddedCoreConfig(
      systemId: 'gba',
      coreName: 'mgba',
      coreFileName: 'libmgba_libretro_android.so',
      extensions: ['gba'],
    ),
    'n64': EmbeddedCoreConfig(
      systemId: 'n64',
      coreName: 'mupen64plus_next_gles3',
      coreFileName: 'libmupen64plus_next_gles3_libretro_android.so',
      extensions: ['n64', 'z64', 'v64'],
    ),
    'sms': EmbeddedCoreConfig(
      systemId: 'sms',
      coreName: 'genesis_plus_gx',
      coreFileName: 'libgenesis_plus_gx_libretro_android.so',
      extensions: ['sms'],
    ),
    'gg': EmbeddedCoreConfig(
      systemId: 'gg',
      coreName: 'genesis_plus_gx',
      coreFileName: 'libgenesis_plus_gx_libretro_android.so',
      extensions: ['gg'],
    ),
    'psp': EmbeddedCoreConfig(
      systemId: 'psp',
      coreName: 'ppsspp',
      coreFileName: 'libppsspp_libretro_android.so',
      extensions: ['iso', 'cso', 'pbp', 'chd'],
    ),
    'nds': EmbeddedCoreConfig(
      systemId: 'nds',
      coreName: 'melonds',
      coreFileName: 'libmelonds_libretro_android.so',
      extensions: ['nds'],
    ),
    'a26': EmbeddedCoreConfig(
      systemId: 'a26',
      coreName: 'stella',
      coreFileName: 'libstella_libretro_android.so',
      extensions: ['a26'],
    ),
    'a78': EmbeddedCoreConfig(
      systemId: 'a78',
      coreName: 'prosystem',
      coreFileName: 'libprosystem_libretro_android.so',
      extensions: ['a78'],
    ),
    'ps1': EmbeddedCoreConfig(
      systemId: 'ps1',
      coreName: 'pcsx_rearmed',
      coreFileName: 'libpcsx_rearmed_libretro_android.so',
      extensions: ['cue', 'bin', 'img', 'chd', 'pbp'],
    ),
    'fbneo': EmbeddedCoreConfig(
      systemId: 'fbneo',
      coreName: 'fbneo',
      coreFileName: 'libfbneo_libretro_android.so',
      extensions: ['zip'],
    ),
    'mame': EmbeddedCoreConfig(
      systemId: 'mame',
      coreName: 'mame2003_plus',
      coreFileName: 'libmame2003_plus_libretro_android.so',
      extensions: ['zip'],
    ),
    'pce': EmbeddedCoreConfig(
      systemId: 'pce',
      coreName: 'mednafen_pce_fast',
      coreFileName: 'libmednafen_pce_fast_libretro_android.so',
      extensions: ['pce'],
    ),
    'lynx': EmbeddedCoreConfig(
      systemId: 'lynx',
      coreName: 'handy',
      coreFileName: 'libhandy_libretro_android.so',
      extensions: ['lnx'],
    ),
    'scd': EmbeddedCoreConfig(
      systemId: 'scd',
      coreName: 'genesis_plus_gx',
      coreFileName: 'libgenesis_plus_gx_libretro_android.so',
      extensions: ['cue', 'bin', 'chd'],
    ),
    'ngp': EmbeddedCoreConfig(
      systemId: 'ngp',
      coreName: 'mednafen_ngp',
      coreFileName: 'libmednafen_ngp_libretro_android.so',
      extensions: ['ngp'],
    ),
    'ngpc': EmbeddedCoreConfig(
      systemId: 'ngpc',
      coreName: 'mednafen_ngp',
      coreFileName: 'libmednafen_ngp_libretro_android.so',
      extensions: ['ngc'],
    ),
    'ws': EmbeddedCoreConfig(
      systemId: 'ws',
      coreName: 'mednafen_wswan',
      coreFileName: 'libmednafen_wswan_libretro_android.so',
      extensions: ['ws'],
    ),
    'wsc': EmbeddedCoreConfig(
      systemId: 'wsc',
      coreName: 'mednafen_wswan',
      coreFileName: 'libmednafen_wswan_libretro_android.so',
      extensions: ['wsc'],
    ),
    'dos': EmbeddedCoreConfig(
      systemId: 'dos',
      coreName: 'dosbox_pure',
      coreFileName: 'libdosbox_pure_libretro_android.so',
      extensions: ['dosz', 'zip'],
    ),
    '3ds': EmbeddedCoreConfig(
      systemId: '3ds',
      coreName: 'citra',
      coreFileName: 'libcitra_libretro_android.so',
      extensions: ['3ds', 'cia'],
    ),
  };

  static bool supports(String systemFolderName) {
    final canonical = EmbeddedSystemAliases.canonicalFor(systemFolderName);
    return _canonicalConfigs.containsKey(canonical);
  }

  static EmbeddedCoreConfig? configFor(String systemFolderName) {
    final canonical = EmbeddedSystemAliases.canonicalFor(systemFolderName);
    final base = _canonicalConfigs[canonical];
    if (base == null) return null;
    if (canonical == systemFolderName) return base;
    return EmbeddedCoreConfig(
      systemId: systemFolderName,
      coreName: base.coreName,
      coreFileName: base.coreFileName,
      extensions: base.extensions,
    );
  }

  /// All unique libretro cores referenced by the registry (for OTA updates).
  static List<EmbeddedCoreConfig> get uniqueCores {
    final seen = <String>{};
    final cores = <EmbeddedCoreConfig>[];
    for (final config in _canonicalConfigs.values) {
      if (seen.add(config.coreName)) {
        cores.add(config);
      }
    }
    return cores;
  }
}
