/// Maps OmiSU [SystemModel.folderName] values to a canonical embedded-play id.
///
/// Canonical ids group systems that share the same libretro core and save layout
/// conventions. Launch still passes the original [folderName] to native code for
/// per-system save directories.
class EmbeddedSystemAliases {
  EmbeddedSystemAliases._();

  static const Map<String, String> folderToCanonical = {
    'fc': 'nes',
    'fds': 'nes',
    'sfc': 'snes',
    'genesis': 'md',
    'mark3': 'sms',
    'mcd': 'scd',
    'tg16': 'pce',
    'arc': 'fbneo',
    'atari2600': 'a26',
    'atari7800': 'a78',
    '2600': 'a26',
    '7800': 'a78',
    'a2600': 'a26',
    'a7800': 'a78',
  };

  static String canonicalFor(String folderName) =>
      folderToCanonical[folderName] ?? folderName;
}
