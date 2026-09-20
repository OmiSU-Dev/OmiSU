import 'package:omisu/models/embedded_system_aliases.dart';

/// Maps OmiSU embedded system ids to [libretro-database](https://github.com/libretro/libretro-database) `cht/` folder names.
class LibretroCheatSystemMap {
  LibretroCheatSystemMap._();

  static const Map<String, String> _canonicalToChtFolder = {
    'nes': 'Nintendo - Nintendo Entertainment System',
    'snes': 'Nintendo - Super Nintendo Entertainment System',
    'md': 'Sega - Mega Drive - Genesis',
    'gb': 'Nintendo - Game Boy',
    'gbc': 'Nintendo - Game Boy Color',
    'gba': 'Nintendo - Game Boy Advance',
    'n64': 'Nintendo - Nintendo 64',
    'sms': 'Sega - Master System - Mark III',
    'gg': 'Sega - Game Gear',
    'psp': 'Sony - PlayStation Portable',
    'nds': 'Nintendo - Nintendo DS',
    'a26': 'Atari - 2600',
    'a78': 'Atari - 7800',
    'ps1': 'Sony - PlayStation',
    'fbneo': 'FBNeo - Arcade Games',
    'mame': 'FBNeo - Arcade Games',
    'pce': 'NEC - PC Engine - TurboGrafx 16',
    'lynx': 'Atari - Lynx',
    'scd': 'Sega - Mega-CD - Sega CD',
    'ngp': 'SNK - Neo Geo Pocket',
    'ngpc': 'SNK - Neo Geo Pocket Color',
    'ws': 'Bandai - WonderSwan',
    'wsc': 'Bandai - WonderSwan Color',
    'dos': 'DOS',
  };

  /// Libretro `cht/<this>/` folder for [systemFolderName], or null if unknown.
  static String? chtFolderForSystem(String systemFolderName) {
    final canonical = EmbeddedSystemAliases.canonicalFor(systemFolderName);
    return _canonicalToChtFolder[canonical];
  }
}
