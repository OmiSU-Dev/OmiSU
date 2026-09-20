/// Which shoulder-button glyphs the shell shows for tab cycling hints.
enum GamepadShoulderStyle {
  /// Xbox-style bumpers (LB / RB).
  bumpers,

  /// Xbox-style triggers (LT / RT).
  triggers;

  static GamepadShoulderStyle fromStored(String? value) {
    switch (value?.toLowerCase()) {
      case 'triggers':
        return GamepadShoulderStyle.triggers;
      default:
        return GamepadShoulderStyle.bumpers;
    }
  }

  String get storageValue => name;

  GamepadShoulderStyle get next =>
      this == GamepadShoulderStyle.bumpers ? triggers : bumpers;
}
