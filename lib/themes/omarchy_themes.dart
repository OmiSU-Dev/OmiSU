import 'package:flutter/material.dart';
import 'package:omisu/themes/omarchy_theme_factory.dart';

/// Omarchy / Retro 82 pack — warm amber (true Retro 82), plus sibling themes
/// from the Omarchy desktop screenshots.
class OmarchyPalettes {
  OmarchyPalettes._();

  /// Official Omarchy "Retro 82" — burnt orange / amber on charcoal.
  static const retro82 = OmarchyPalette(
    id: 'retro82',
    displayName: 'Retro 82',
    primary: Color(0xFFE0A040),
    onPrimary: Color(0xFF1A1208),
    secondary: Color(0xFFC4883A),
    background: Color(0xFF12100C),
    surface: Color(0xFF1C1812),
    onSurface: Color(0xFFF0E6D8),
    outline: Color(0xFF4A3C28),
    error: Color(0xFFE06C75),
    dustPrimary: Color(0xFFE0A040),
    dustSecondary: Color(0xFF8B5A2B),
    density: 0.6,
    batteryFull: Color(0xFF9ECE6A),
    batteryMedium: Color(0xFFE0A040),
    batteryLow: Color(0xFFE06C75),
  );

  /// Soft peach / sage — Omarchy marketing site vibe.
  static const omarchy = OmarchyPalette(
    id: 'omarchy',
    displayName: 'Omarchy',
    primary: Color(0xFFC4A574),
    onPrimary: Color(0xFF121212),
    secondary: Color(0xFF9ECE6A),
    background: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    onSurface: Color(0xFFE8E4DC),
    outline: Color(0xFF3A3830),
    error: Color(0xFFE06C75),
    dustPrimary: Color(0xFFC4A574),
    dustSecondary: Color(0xFF9ECE6A),
    density: 0.7,
  );

  static const solitude = OmarchyPalette(
    id: 'solitude',
    displayName: 'Solitude',
    primary: Color(0xFFC8C2B4),
    onPrimary: Color(0xFF0A0A0A),
    secondary: Color(0xFF8A8680),
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    onSurface: Color(0xFFEDEAE4),
    outline: Color(0xFF2E2E2E),
    error: Color(0xFFCF6A6A),
    dustPrimary: Color(0xFF8A8680),
    dustSecondary: Color(0xFF4A4844),
    density: 0.25,
  );

  static const vantablack = OmarchyPalette(
    id: 'vantablack',
    displayName: 'Vantablack',
    primary: Color(0xFFE8E8E8),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF9A9A9A),
    background: Color(0xFF000000),
    surface: Color(0xFF0D0D0D),
    onSurface: Color(0xFFF2F2F2),
    outline: Color(0xFF2A2A2A),
    error: Color(0xFFCF6A6A),
    dustPrimary: Color(0xFF666666),
    dustSecondary: Color(0xFF333333),
    density: 0.2,
  );

  static const ethereal = OmarchyPalette(
    id: 'ethereal',
    displayName: 'Ethereal',
    primary: Color(0xFF7DCFFF),
    onPrimary: Color(0xFF0B0E14),
    secondary: Color(0xFFBB9AF7),
    background: Color(0xFF0B0E14),
    surface: Color(0xFF151A23),
    onSurface: Color(0xFFC0CAF5),
    outline: Color(0xFF3B4261),
    error: Color(0xFFF7768E),
    tertiary: Color(0xFFE0A040),
    dustPrimary: Color(0xFF7DCFFF),
    dustSecondary: Color(0xFFBB9AF7),
    density: 0.5,
  );

  static const everforest = OmarchyPalette(
    id: 'everforest',
    displayName: 'Everforest',
    primary: Color(0xFFA7C080),
    onPrimary: Color(0xFF2D353B),
    secondary: Color(0xFF83C092),
    background: Color(0xFF2D353B),
    surface: Color(0xFF343F44),
    onSurface: Color(0xFFD3C6AA),
    outline: Color(0xFF4F5B58),
    error: Color(0xFFE67E80),
    dustPrimary: Color(0xFFA7C080),
    dustSecondary: Color(0xFF7A8478),
    density: 0.45,
  );

  static const gruvbox = OmarchyPalette(
    id: 'gruvbox',
    displayName: 'Gruvbox',
    primary: Color(0xFFD79921),
    onPrimary: Color(0xFF282828),
    secondary: Color(0xFFB8BB26),
    background: Color(0xFF282828),
    surface: Color(0xFF3C3836),
    onSurface: Color(0xFFEBDBB2),
    outline: Color(0xFF504945),
    error: Color(0xFFFB4934),
    dustPrimary: Color(0xFFD79921),
    dustSecondary: Color(0xFF8F3F71),
    density: 0.55,
  );

  static const hackerman = OmarchyPalette(
    id: 'hackerman',
    displayName: 'Hackerman',
    primary: Color(0xFF00FF66),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF00E5FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A120A),
    onSurface: Color(0xFFB8FFC8),
    outline: Color(0xFF1A3A22),
    error: Color(0xFFFF3355),
    dustPrimary: Color(0xFF00FF66),
    dustSecondary: Color(0xFF00E5FF),
    density: 0.65,
  );

  static const kanagawa = OmarchyPalette(
    id: 'kanagawa',
    displayName: 'Kanagawa',
    primary: Color(0xFFC0A36E),
    onPrimary: Color(0xFF1F1F28),
    secondary: Color(0xFF7E9CD8),
    background: Color(0xFF1F1F28),
    surface: Color(0xFF2A2A37),
    onSurface: Color(0xFFDCD7BA),
    outline: Color(0xFF54546D),
    error: Color(0xFFE82424),
    dustPrimary: Color(0xFFC0A36E),
    dustSecondary: Color(0xFF7E9CD8),
    density: 0.5,
  );

  static const catppuccin = OmarchyPalette(
    id: 'catppuccin',
    displayName: 'Catppuccin',
    primary: Color(0xFFCBA6F7),
    onPrimary: Color(0xFF1E1E2E),
    secondary: Color(0xFF89B4FA),
    background: Color(0xFF1E1E2E),
    surface: Color(0xFF313244),
    onSurface: Color(0xFFCDD6F4),
    outline: Color(0xFF45475A),
    error: Color(0xFFF38BA8),
    dustPrimary: Color(0xFFCBA6F7),
    dustSecondary: Color(0xFFF5C2E7),
    density: 0.55,
  );

  static const List<OmarchyPalette> all = [
    retro82,
    omarchy,
    solitude,
    vantablack,
    ethereal,
    everforest,
    gruvbox,
    hackerman,
    kanagawa,
    catppuccin,
  ];
}

final ThemeData omarchyTheme = buildOmarchyTheme(OmarchyPalettes.omarchy);
final ThemeData solitudeTheme = buildOmarchyTheme(OmarchyPalettes.solitude);
final ThemeData vantablackTheme = buildOmarchyTheme(OmarchyPalettes.vantablack);
final ThemeData etherealTheme = buildOmarchyTheme(OmarchyPalettes.ethereal);
final ThemeData everforestTheme = buildOmarchyTheme(OmarchyPalettes.everforest);
final ThemeData gruvboxTheme = buildOmarchyTheme(OmarchyPalettes.gruvbox);
final ThemeData hackermanTheme = buildOmarchyTheme(OmarchyPalettes.hackerman);
final ThemeData kanagawaTheme = buildOmarchyTheme(OmarchyPalettes.kanagawa);
final ThemeData catppuccinTheme = buildOmarchyTheme(OmarchyPalettes.catppuccin);

class OmarchySiteCustomColors extends OmarchyCustomColors {
  OmarchySiteCustomColors() : super(OmarchyPalettes.omarchy);
}

class SolitudeCustomColors extends OmarchyCustomColors {
  SolitudeCustomColors() : super(OmarchyPalettes.solitude);
}

class VantablackCustomColors extends OmarchyCustomColors {
  VantablackCustomColors() : super(OmarchyPalettes.vantablack);
}

class EtherealCustomColors extends OmarchyCustomColors {
  EtherealCustomColors() : super(OmarchyPalettes.ethereal);
}

class EverforestCustomColors extends OmarchyCustomColors {
  EverforestCustomColors() : super(OmarchyPalettes.everforest);
}

class GruvboxCustomColors extends OmarchyCustomColors {
  GruvboxCustomColors() : super(OmarchyPalettes.gruvbox);
}

class HackermanCustomColors extends OmarchyCustomColors {
  HackermanCustomColors() : super(OmarchyPalettes.hackerman);
}

class KanagawaCustomColors extends OmarchyCustomColors {
  KanagawaCustomColors() : super(OmarchyPalettes.kanagawa);
}

class CatppuccinCustomColors extends OmarchyCustomColors {
  CatppuccinCustomColors() : super(OmarchyPalettes.catppuccin);
}
