import 'package:omisu/models/embedded_system_aliases.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';

/// Curated in-game core options safe to expose during embedded play.
///
/// Based on Lemuroid's [exposedSettings] whitelist (not advanced/dangerous
/// options like dynarec, JIT toggles, or link-cable networking).
const Map<String, Set<String>> _allowedKeysBySystem = {
  'a26': {
    'stella_filter',
    'stella_crop_hoverscan',
  },
  'nes': {
    'fceumm_overscan_h',
    'fceumm_overscan_v',
  },
  'snes': {},
  'sms': {
    'genesis_plus_gx_blargg_ntsc_filter',
  },
  'md': {
    'genesis_plus_gx_blargg_ntsc_filter',
  },
  'scd': {
    'genesis_plus_gx_blargg_ntsc_filter',
  },
  'gg': {
    'genesis_plus_gx_lcd_filter',
  },
  'gb': {
    'gambatte_gb_colorization',
    'gambatte_gb_internal_palette',
    'gambatte_mix_frames',
    'gambatte_dark_filter_level',
  },
  'gbc': {
    'gambatte_mix_frames',
    'gambatte_gbc_color_correction',
    'gambatte_dark_filter_level',
  },
  'gba': {
    'mgba_solar_sensor_level',
    'mgba_interframe_blending',
    'mgba_frameskip',
    'mgba_color_correction',
  },
  'n64': {
    'mupen64plus-43screensize',
    'mupen64plus-cpucore',
    'mupen64plus-BilinearMode',
    'mupen64plus-pak1',
    'mupen64plus-pak2',
  },
  'ps1': {
    'pcsx_rearmed_frameskip',
  },
  'psp': {
    'ppsspp_auto_frameskip',
    'ppsspp_frameskip',
  },
  'fbneo': {
    'fbneo-frameskip',
    'fbneo-cpu-speed-adjust',
  },
  'mame': {},
  'nds': {
    'melonds_screen_layout1',
    'melonds_mic_input',
  },
  'lynx': {
    'handy_rot',
  },
  'pce': {},
  'ngp': {},
  'ngpc': {},
  'ws': {
    'wswan_rotate_display',
    'wswan_mono_palette',
  },
  'wsc': {
    'wswan_rotate_display',
  },
  'a78': {},
  'dos': {},
  '3ds': {
    'citra_layout_option',
    'citra_resolution_factor',
  },
};

/// Keys/patterns that should never be user-tweakable mid-game.
const _blockedKeyPatterns = [
  '_link',
  'link_',
  'network',
  'bios',
  '_boot',
  'boot_',
  'dynarec',
  '_drc',
  '_jit',
  'threaded_renderer',
  'shader_cache',
  'use_acc_mul',
  'use_acc_geo_shaders',
  'cpu_core',
  'internal_resolution',
  'texture_scaling',
];

bool isBlockedCoreOptionKey(String key) {
  final normalized = key.toLowerCase();
  for (final pattern in _blockedKeyPatterns) {
    if (normalized.contains(pattern)) {
      return true;
    }
  }
  return false;
}

Set<String> allowedCoreOptionKeysFor(String systemFolder) {
  final canonical = EmbeddedSystemAliases.canonicalFor(systemFolder);
  return _allowedKeysBySystem[canonical] ?? const {};
}

bool isUserFacingCoreOption({
  required String systemFolder,
  required String key,
}) {
  if (isBlockedCoreOptionKey(key)) return false;
  final allowed = allowedCoreOptionKeysFor(systemFolder);
  return allowed.contains(key);
}

List<EmbeddedCoreVariable> filterUserFacingCoreOptions({
  required String systemFolder,
  required List<EmbeddedCoreVariable> variables,
}) {
  return variables
      .where(
        (variable) => isUserFacingCoreOption(
          systemFolder: systemFolder,
          key: variable.key,
        ),
      )
      .toList();
}
