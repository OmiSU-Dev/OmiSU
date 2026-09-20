import 'package:flutter/material.dart';

/// Shared accent helpers. Theme-specific colors live on [ColorScheme] /
/// [AmbientChrome]; these defaults match Retro 82 amber for hardcoded chrome.
class OmisuAccent {
  OmisuAccent._();

  /// Amber → copper → deep brown (Retro 82).
  static const List<Color> focusGradient = [
    Color(0xFFE8B86D),
    Color(0xFFE0A040),
    Color(0xFFC4883A),
    Color(0xFF8B5A2B),
  ];

  /// Near-black charcoal used behind HUD panels and the shell backdrop.
  static const Color synthBase = Color(0xFF12100C);

  /// Quiet warm wash at the bottom of the shell.
  static const List<Color> horizonGradient = [
    Color(0xFF3A2A18),
    Color(0xFF1C1812),
    Color(0xFF12100C),
  ];

  static const LinearGradient focusRingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: focusGradient,
  );

  static const String fontFamily = 'JetBrainsMonoNerdFont';

  /// Retro 82 / Omarchy amber brand.
  static const Color brandGreen = Color(0xFFE0A040);

  /// Darker copper for pressed / secondary fills.
  static const Color brandGreenDeep = Color(0xFFC4883A);

  /// Primary confirm actions (A / Enter / Play).
  static BoxDecoration primaryActionDecoration(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return BoxDecoration(
      color: primary,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: primary.withValues(alpha: 0.85), width: 1),
    );
  }

  /// Secondary actions (Y / Options / Back).
  static BoxDecoration secondaryActionDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(2),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.65),
        width: 1,
      ),
    );
  }

  static Color primaryActionForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  static Color secondaryActionForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static bool isLegacyFooterBackground(Color? color, ColorScheme scheme) {
    if (color == null) return false;
    return color == scheme.tertiary || color == scheme.tertiaryFixed;
  }

  static bool isLegacyFooterText(Color? color, ColorScheme scheme) {
    if (color == null) return false;
    return color == scheme.onTertiary || color == scheme.onTertiaryFixed;
  }
}
