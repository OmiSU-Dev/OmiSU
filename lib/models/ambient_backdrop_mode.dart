/// Soft shell backdrop behaviour for Omarchy-style themes.
enum AmbientBackdropMode {
  /// No wash / pixel dust — Solitude-style stillness.
  off,

  /// Static dust + very slow wash (cheap).
  subtle,

  /// Subtle plus eased wash when home selection / tab focus changes.
  reactive,

  /// Omarchy screensaver ASCII art driven by grid focus title.
  screensaver;

  static AmbientBackdropMode fromStored(String? value) {
    switch (value?.toLowerCase()) {
      case 'subtle':
        return AmbientBackdropMode.subtle;
      case 'reactive':
        return AmbientBackdropMode.reactive;
      case 'screensaver':
        return AmbientBackdropMode.screensaver;
      default:
        return AmbientBackdropMode.off;
    }
  }

  String get storageValue => name;

  AmbientBackdropMode get next {
    const values = AmbientBackdropMode.values;
    return values[(index + 1) % values.length];
  }
}
