import 'dart:ui';

import 'package:flutter/material.dart';

/// Per-theme ambient backdrop tokens (pixel dust + wash). Shared animator
/// reads this from [ThemeData.extensions]; themes only supply colors/density.
@immutable
class AmbientChrome extends ThemeExtension<AmbientChrome> {
  const AmbientChrome({
    required this.dustPrimary,
    required this.dustSecondary,
    this.density = 0.55,
  });

  final Color dustPrimary;
  final Color dustSecondary;

  /// 0–1 scale for particle count / wash strength.
  final double density;

  static AmbientChrome of(BuildContext context) {
    return Theme.of(context).extension<AmbientChrome>() ??
        AmbientChrome(
          dustPrimary: Theme.of(context).colorScheme.primary,
          dustSecondary: Theme.of(context).colorScheme.secondary,
        );
  }

  @override
  AmbientChrome copyWith({
    Color? dustPrimary,
    Color? dustSecondary,
    double? density,
  }) {
    return AmbientChrome(
      dustPrimary: dustPrimary ?? this.dustPrimary,
      dustSecondary: dustSecondary ?? this.dustSecondary,
      density: density ?? this.density,
    );
  }

  @override
  AmbientChrome lerp(ThemeExtension<AmbientChrome>? other, double t) {
    if (other is! AmbientChrome) return this;
    return AmbientChrome(
      dustPrimary: Color.lerp(dustPrimary, other.dustPrimary, t)!,
      dustSecondary: Color.lerp(dustSecondary, other.dustSecondary, t)!,
      density: lerpDouble(density, other.density, t)!,
    );
  }
}
