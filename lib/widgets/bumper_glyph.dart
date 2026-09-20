import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/models/gamepad_shoulder_style.dart';

/// An LB/RB bumper glyph lifted off the background by a soft halo.
///
/// The glyphs are tinted [ColorScheme.onSurface] and are drawn outside the tab
/// pills, directly over whatever fanart is behind the chrome — without the
/// pill's backing they wash out on light artwork.
///
/// The halo is a single blurred copy of the glyph behind it, not an outline.
/// A ring of offset copies gives a crisp edge that reads as a hard chip around
/// a shape this small however far its opacity is dropped; blurring removes the
/// edge entirely, so the glyph gains separation without gaining weight.
///
/// The asset is a filled blob with its "LB"/"RB" lettering knocked out to
/// transparent, so artwork behind would otherwise show through the letters and
/// leave them muddy. Backing it with the same asset does not help — the holes
/// line up exactly and the copy stays hidden — so a `_filled` variant of each
/// glyph, identical but with the lettering closed, is drawn underneath. It is
/// covered everywhere the glyph is opaque and shows only through the letters,
/// giving the legend a solid colour. Its silhouette matches the glyph's
/// exactly, so it fills without ringing.
///
/// The halo uses the filled variant too, so the blur reads as one soft shape
/// rather than smearing through the lettering.
///
/// Tune with [_haloAlpha] (how dark) and [_haloBlur] (how far it spreads).
class BumperGlyph extends StatelessWidget {
  final bool isLeft;
  final double? size;
  final GamepadShoulderStyle style;

  const BumperGlyph({
    super.key,
    required this.isLeft,
    this.size,
    this.style = GamepadShoulderStyle.bumpers,
  });

  /// Strength of the halo. Low enough to stay a hint rather than a shadow.
  static const double _haloAlpha = 0.5;

  /// Blur sigma, in logical pixels before screenutil scaling.
  static const double _haloBlur = 1.5;

  @override
  Widget build(BuildContext context) {
    final double dimension = size ?? 22.r;
    final scheme = Theme.of(context).colorScheme;

    if (style == GamepadShoulderStyle.triggers) {
      final asset = isLeft
          ? 'assets/images/gamepad/Xbox_LT_trigger.png'
          : 'assets/images/gamepad/Xbox_RT_trigger.png';
      return _ShoulderGlyphStack(
        dimension: dimension,
        scheme: scheme,
        asset: asset,
        filledAsset: asset,
        useFilledBacking: false,
      );
    }

    final asset = isLeft
        ? 'assets/images/gamepad/Xbox_LB_bumper.png'
        : 'assets/images/gamepad/Xbox_RB_bumper.png';
    final filledAsset = isLeft
        ? 'assets/images/gamepad/Xbox_LB_bumper_filled.png'
        : 'assets/images/gamepad/Xbox_RB_bumper_filled.png';

    return _ShoulderGlyphStack(
      dimension: dimension,
      scheme: scheme,
      asset: asset,
      filledAsset: filledAsset,
      useFilledBacking: true,
    );
  }
}

class _ShoulderGlyphStack extends StatelessWidget {
  const _ShoulderGlyphStack({
    required this.dimension,
    required this.scheme,
    required this.asset,
    required this.filledAsset,
    required this.useFilledBacking,
  });

  final double dimension;
  final ColorScheme scheme;
  final String asset;
  final String filledAsset;
  final bool useFilledBacking;

  Widget _copy(String path, Color color) =>
      Image.asset(path, width: dimension, height: dimension, color: color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: BumperGlyph._haloBlur.r,
              sigmaY: BumperGlyph._haloBlur.r,
            ),
            child: _copy(
              filledAsset,
              scheme.surface.withValues(alpha: BumperGlyph._haloAlpha),
            ),
          ),
          if (useFilledBacking)
            _copy(filledAsset, scheme.surface)
          else
            _copy(asset, scheme.surface.withValues(alpha: 0.92)),
          _copy(asset, scheme.onSurface),
        ],
      ),
    );
  }
}
