import 'package:flutter/material.dart';
import 'package:omisu/themes/omarchy_theme_factory.dart';
import 'package:omisu/themes/omarchy_themes.dart';

/// Retro 82 — Omarchy warm amber terminal (matches stock Omarchy Retro 82).
final ThemeData retro82Theme = buildOmarchyTheme(OmarchyPalettes.retro82);

class Retro82CustomColors extends OmarchyCustomColors {
  Retro82CustomColors() : super(OmarchyPalettes.retro82);
}
