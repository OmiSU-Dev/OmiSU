import 'package:omisu/services/embedded/embedded_core_option_allowlist.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';

/// Libretro-style option descriptions for allowlisted keys (offline Play tab).
const Map<String, String> _catalogDescriptions = {
  'stella_filter': 'Stella TV filter; disabled|enabled',
  'stella_crop_hoverscan': 'Crop horizontal overscan; disabled|enabled',
  'fceumm_overscan_h': 'Horizontal overscan; disabled|enabled',
  'fceumm_overscan_v': 'Vertical overscan; disabled|enabled',
  'genesis_plus_gx_blargg_ntsc_filter': 'NTSC filter; disabled|monochrome|composite|svideo|rgb|badly adjusted',
  'genesis_plus_gx_lcd_filter': 'LCD ghosting; disabled|enabled',
  'gambatte_gb_colorization': 'GB colorization; disabled|auto|internal|custom 1|custom 2',
  'gambatte_gb_internal_palette': 'Internal palette; Special 1|Special 2|Special 3',
  'gambatte_mix_frames': 'LCD ghosting; disabled|mix|auto',
  'gambatte_dark_filter_level': 'Dark filter; 0|1|2|3|4|5|6|7|8|9|10',
  'gambatte_gbc_color_correction': 'Color correction; disabled|always',
  'mgba_solar_sensor_level': 'Solar sensor; 0|1|2|3|4|5|6|7|8|9|10',
  'mgba_interframe_blending': 'LCD ghosting; disabled|mix|smart',
  'mgba_frameskip': 'Frameskip; disabled|auto|auto_threshold|fixed_interval',
  'mgba_color_correction': 'Color correction; OFF|GBA|GBC|Auto',
  'mupen64plus-43screensize': 'Aspect ratio; 4:3|16:9|16:10',
  'mupen64plus-cpucore': 'CPU core; dynamic_recompiler|pure_interpreter|cached_interpreter',
  'mupen64plus-BilinearMode': 'Bilinear filter; standard|3point',
  'mupen64plus-pak1': 'Player 1 pak; memory|rumble|none',
  'mupen64plus-pak2': 'Player 2 pak; memory|rumble|none',
  'pcsx_rearmed_frameskip': 'Frameskip; 0|1|2|3|4|5',
  'ppsspp_auto_frameskip': 'Auto frameskip; disabled|enabled',
  'ppsspp_frameskip': 'Frameskip; 0|1|2|3|4|5|6|7|8|9',
  'fbneo-frameskip': 'Frameskip; 0|1|2|3|4|5',
  'fbneo-cpu-speed-adjust': 'CPU speed; 100|110|120|130|140|150',
  'melonds_screen_layout1': 'Screen layout; top-bottom|bottom-top|left-right|right-left|hybrid-top|hybrid-bottom',
  'melonds_mic_input': 'Microphone; silence|microphone',
  'handy_rot': 'Rotation; disabled|90|180|270',
  'wswan_rotate_display': 'Rotation; manual|landscape|portrait',
  'wswan_mono_palette': 'Palette; default|wsc|wsc_backlit|ws|kreidels|ghost|pocket|pocket_backlight',
  'citra_layout_option': 'Screen layout; single screen|large screen|side screen',
  'citra_resolution_factor': 'Resolution; 1|2|3|4',
};

List<EmbeddedCoreVariable> catalogCoreOptionsForSystem({
  required String systemFolder,
  Map<String, String> savedValues = const {},
}) {
  final keys = allowedCoreOptionKeysFor(systemFolder);
  final list = <EmbeddedCoreVariable>[];
  for (final key in keys) {
    list.add(
      EmbeddedCoreVariable(
        key: key,
        value: savedValues[key],
        description: _catalogDescriptions[key],
      ),
    );
  }
  list.sort((a, b) => a.key.compareTo(b.key));
  return list;
}
