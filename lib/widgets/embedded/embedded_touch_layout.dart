import 'package:omisu/models/embedded_system_aliases.dart';

/// Face-button arrangement on the right side of the touch overlay.
enum TouchFaceLayout {
  /// D-pad + A/B + Start/Select (Game Boy, NES, etc.).
  nintendo2,

  /// Diamond A/B/X/Y + shoulders (SNES, PC Engine, etc.).
  nintendo4,

  /// A/B/C vertical stack (Genesis 3-button).
  genesis3,

  /// Six face buttons in two columns (Genesis 6-button).
  genesis6,

  /// Four face buttons + L1/R1/L2/R2 (PlayStation family).
  playstation,

  /// A/B/X/Y as C-buttons + A/B/Z/L/R (N64).
  n64,

  /// 2×2 grid (arcade / MAME).
  arcade4,
}

/// Describes which controls appear for a given console during embedded play.
class EmbeddedTouchLayoutConfig {
  const EmbeddedTouchLayoutConfig({
    required this.faceLayout,
    this.showShoulders = false,
    this.showTriggers = false,
    this.showStart = true,
    this.showSelect = true,
  });

  final TouchFaceLayout faceLayout;
  final bool showShoulders;
  final bool showTriggers;
  final bool showStart;
  final bool showSelect;

  static const EmbeddedTouchLayoutConfig gameBoy = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.nintendo2,
  );

  static const EmbeddedTouchLayoutConfig nes = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.nintendo2,
  );

  static const EmbeddedTouchLayoutConfig snes = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.nintendo4,
    showShoulders: true,
  );

  static const EmbeddedTouchLayoutConfig gba = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.nintendo2,
    showShoulders: true,
  );

  static const EmbeddedTouchLayoutConfig genesis = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.genesis6,
  );

  static const EmbeddedTouchLayoutConfig playstation = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.playstation,
    showShoulders: true,
    showTriggers: true,
  );

  static const EmbeddedTouchLayoutConfig n64 = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.n64,
    showShoulders: true,
    showSelect: false,
  );

  static const EmbeddedTouchLayoutConfig arcade = EmbeddedTouchLayoutConfig(
    faceLayout: TouchFaceLayout.arcade4,
    showStart: false,
    showSelect: false,
  );

  static const EmbeddedTouchLayoutConfig defaultLayout = gameBoy;

  static const Map<String, EmbeddedTouchLayoutConfig> _byCanonical = {
    'gb': gameBoy,
    'gbc': gameBoy,
    'gg': gameBoy,
    'lynx': gameBoy,
    'ngp': gameBoy,
    'ngpc': gameBoy,
    'ws': gameBoy,
    'wsc': gameBoy,
    'nes': nes,
    'a26': nes,
    'a78': nes,
    'sms': nes,
    'snes': snes,
    'pce': snes,
    'gba': gba,
    'md': genesis,
    'scd': genesis,
    'ps1': playstation,
    'psp': playstation,
    'n64': n64,
    'fbneo': arcade,
    'mame': arcade,
    'nds': snes,
    '3ds': snes,
    'dos': snes,
  };

  /// Resolves the touch layout for an OmiSU system folder (e.g. `sfc` → SNES).
  static EmbeddedTouchLayoutConfig forSystem(String systemFolder) {
    final canonical = EmbeddedSystemAliases.canonicalFor(systemFolder);
    return _byCanonical[canonical] ?? defaultLayout;
  }
}
