import 'package:flutter/widgets.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// Nerd Font glyphs from the bundled JetBrains Mono Nerd Font.
///
/// Codepoints are Material Design / Font Awesome icons in the Nerd Font PUA —
/// verified present in `JetBrainsMonoNerdFont-Regular.ttf`.
class OmisuNerdIcons {
  OmisuNerdIcons._();

  static const String _family = OmisuAccent.fontFamily;

  static const IconData bell = IconData(0xF009A, fontFamily: _family);
  static const IconData bellRing = IconData(0xF009E, fontFamily: _family);

  static const IconData batteryFull = IconData(0xF240, fontFamily: _family);
  static const IconData battery75 = IconData(0xF241, fontFamily: _family);
  static const IconData battery50 = IconData(0xF242, fontFamily: _family);
  static const IconData battery25 = IconData(0xF243, fontFamily: _family);
  static const IconData batteryEmpty = IconData(0xF244, fontFamily: _family);

  /// MD charging bolt battery (used while charging / full).
  static const IconData batteryCharging = IconData(
    0xF0085,
    fontFamily: _family,
  );

  /// Segmented LCD-style battery for a given charge level.
  static IconData batteryForLevel(int level, {required bool charging}) {
    if (charging || level < 0) return batteryCharging;
    if (level >= 90) return batteryFull;
    if (level >= 65) return battery75;
    if (level >= 40) return battery50;
    if (level >= 15) return battery25;
    return batteryEmpty;
  }
}
