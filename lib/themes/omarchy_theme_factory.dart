import 'package:flutter/material.dart';
import 'package:omisu/themes/ambient_chrome.dart';
import 'package:omisu/themes/chrome_surface.dart';
import 'package:omisu/themes/corner_radii.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// Color recipe for an Omarchy-style terminal theme.
class OmarchyPalette {
  const OmarchyPalette({
    required this.id,
    required this.displayName,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.outline,
    required this.error,
    this.tertiary,
    this.dustPrimary,
    this.dustSecondary,
    this.density = 0.55,
    this.batteryFull,
    this.batteryMedium,
    this.batteryLow,
  });

  final String id;
  final String displayName;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color outline;
  final Color error;
  final Color? tertiary;
  final Color? dustPrimary;
  final Color? dustSecondary;
  final double density;
  final Color? batteryFull;
  final Color? batteryMedium;
  final Color? batteryLow;
}

/// Builds a sharp-corner Omarchy chrome [ThemeData] from a [OmarchyPalette].
ThemeData buildOmarchyTheme(OmarchyPalette p) {
  final tertiary = p.tertiary ?? p.secondary;
  final onSurface = p.onSurface;
  TextStyle mono(double size, {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        color: onSurface,
        fontSize: size,
        fontWeight: weight,
        fontFamily: OmisuAccent.fontFamily,
        letterSpacing: 0.35,
        height: 1.25,
      );

  final textTheme = TextTheme(
    displayLarge: mono(32, weight: FontWeight.bold),
    displayMedium: mono(28, weight: FontWeight.bold),
    displaySmall: mono(24, weight: FontWeight.w600),
    headlineLarge: mono(22, weight: FontWeight.w600),
    headlineMedium: mono(20, weight: FontWeight.w600),
    headlineSmall: mono(18, weight: FontWeight.w600),
    titleLarge: mono(20, weight: FontWeight.w600),
    titleMedium: mono(16, weight: FontWeight.w500),
    titleSmall: mono(14, weight: FontWeight.w500),
    bodyLarge: mono(15),
    bodyMedium: mono(13),
    bodySmall: mono(11),
    labelLarge: mono(13, weight: FontWeight.w500),
    labelMedium: mono(12, weight: FontWeight.w500),
    labelSmall: mono(10, weight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: OmisuAccent.fontFamily,
    colorScheme: ColorScheme.dark(
      primary: p.primary,
      secondary: p.secondary,
      tertiary: tertiary,
      tertiaryFixed: p.surface,
      surface: p.surface,
      surfaceContainerHighest: Color.lerp(p.surface, p.onSurface, 0.06)!,
      onPrimary: p.onPrimary,
      onSecondary: p.onPrimary,
      onTertiary: p.onPrimary,
      onTertiaryFixed: onSurface,
      onSurface: onSurface,
      error: p.error,
      onError: p.onPrimary,
      outline: p.outline,
      shadow: const Color(0xFF050505),
    ),
    cardColor: p.surface,
    scaffoldBackgroundColor: p.background,
    extensions: [
      CornerRadii.retro82(),
      ChromeSurface.glass(),
      AmbientChrome(
        dustPrimary: p.dustPrimary ?? p.primary,
        dustSecondary: p.dustSecondary ?? p.secondary,
        density: p.density,
      ),
    ],
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: p.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color.lerp(p.surface, p.onSurface, 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide(color: p.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide(color: p.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: p.outline),
      ),
    ),
  );
}

/// Battery / status custom colors matching a palette.
class OmarchyCustomColors {
  OmarchyCustomColors(this.palette);

  final OmarchyPalette palette;

  Color get batteryFull => palette.batteryFull ?? palette.primary;
  Color get batteryMedium =>
      palette.batteryMedium ?? const Color(0xFFC9B458);
  Color get batteryLow => palette.batteryLow ?? palette.error;
  Color get batteryPower => palette.secondary;

  Color get errorColor => palette.error;
  Color get onErrorColor => palette.onPrimary;
  Color get successColor => palette.batteryFull ?? palette.primary;
  Color get onSuccessColor => palette.onPrimary;
  Color get infoColor => palette.secondary;
  Color get onInfoColor => palette.onPrimary;
  Color get warningColor =>
      palette.batteryMedium ?? const Color(0xFFC9B458);
  Color get onWarningColor => palette.onPrimary;
}
