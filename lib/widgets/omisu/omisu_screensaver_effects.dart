import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// TTE-inspired screensaver effects (Omarchy ttfx flagship subset).
enum OmisuScreensaverEffect {
  shimmer,
  wave,
  pulse,
  glitch,
  blackhole,
  thunderstorm,
  matrix,
  decrypt,
  sweep,
}

extension OmisuScreensaverEffectX on OmisuScreensaverEffect {
  Duration get cycleDuration => switch (this) {
        OmisuScreensaverEffect.blackhole => const Duration(seconds: 7),
        OmisuScreensaverEffect.thunderstorm => const Duration(seconds: 5),
        OmisuScreensaverEffect.matrix => const Duration(seconds: 6),
        OmisuScreensaverEffect.decrypt => const Duration(seconds: 5),
        OmisuScreensaverEffect.sweep => const Duration(seconds: 4),
        _ => const Duration(seconds: 8),
      };

  bool get isFlagship => switch (this) {
        OmisuScreensaverEffect.blackhole ||
        OmisuScreensaverEffect.thunderstorm ||
        OmisuScreensaverEffect.matrix ||
        OmisuScreensaverEffect.decrypt ||
        OmisuScreensaverEffect.sweep =>
          true,
        _ => false,
      };
}

/// Paints block ASCII with per-character effect transforms.
class OmisuScreensaverEffectPainter extends CustomPainter {
  OmisuScreensaverEffectPainter({
    required this.lines,
    required this.color,
    required this.fontSize,
    required this.effect,
    required this.phase,
    required this.shimmer,
    required this.wave,
    required this.pulse,
    required this.glitch,
    this.lineHeight = 0.92,
  });

  final List<String> lines;
  final Color color;
  final double fontSize;
  final OmisuScreensaverEffect effect;
  final double phase;
  final double shimmer;
  final double wave;
  final double pulse;
  final double glitch;
  final double lineHeight;

  static const _matrixChars = 'アイウエオカキクケコ0123456789';
  static final _rng = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty) return;

    final charW = fontSize * 0.58;
    final charH = fontSize * lineHeight;
    final maxCols = lines.fold(0, (a, b) => math.max(a, b.length));
    final blockW = maxCols * charW;
    final blockH = lines.length * charH;
    final originX = (size.width - blockW) / 2;
    final originY = (size.height - blockH) / 2;
    final centerX = originX + blockW / 2;
    final centerY = originY + blockH / 2;

    final textStyle = TextStyle(
      fontFamily: OmisuAccent.fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );

    for (var row = 0; row < lines.length; row++) {
      final line = lines[row];
      for (var col = 0; col < line.length; col++) {
        final ch = line[col];
        if (ch == ' ') continue;

        final baseX = originX + col * charW;
        final baseY = originY + row * charH;
        final dx = baseX - centerX;
        final dy = baseY - centerY;
        final dist = math.sqrt(dx * dx + dy * dy);
        final maxDist = math.max(blockW, blockH) * 0.55;

        final resolved = _resolveChar(ch, row, col, dist, maxDist);
        final alpha = _resolveAlpha(row, col, dist, maxDist);
        if (alpha <= 0.02) continue;

        final offset = _resolveOffset(dx, dy, dist, maxDist, row, col);
        final fg = _resolveColor(alpha);

        final painter = TextPainter(
          text: TextSpan(text: resolved, style: textStyle.copyWith(color: fg)),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, Offset(baseX + offset.dx, baseY + offset.dy));
      }
    }
  }

  String _resolveChar(String ch, int row, int col, double dist, double maxDist) {
    switch (effect) {
      case OmisuScreensaverEffect.matrix:
        final colSeed = col * 17 + row;
        final fall = (phase * 6 + col * 0.08) % 1.0;
        final revealRow = (lines.length * (1 - fall)).floor();
        if (row < revealRow - 1) {
          return _matrixChars[(colSeed + (phase * 20).floor()) % _matrixChars.length];
        }
        return ch;
      case OmisuScreensaverEffect.decrypt:
        final delay = (col * 0.07 + row * 0.04);
        if (phase < delay) {
          return String.fromCharCode(0x41 + ((col * 3 + row * 5 + (phase * 40).floor()) % 26));
        }
        if (phase < delay + 0.08) {
          return _matrixChars[(col + row) % _matrixChars.length];
        }
        return ch;
      default:
        return ch;
    }
  }

  double _resolveAlpha(int row, int col, double dist, double maxDist) {
    switch (effect) {
      case OmisuScreensaverEffect.pulse:
        return 0.55 + 0.45 * pulse;
      case OmisuScreensaverEffect.sweep:
        final maxCols = lines.fold(0, (a, b) => math.max(a, b.length));
        final sweepX = phase * (maxCols + 4) - 2;
        if (col <= sweepX) return 1.0;
        if (col <= sweepX + 1.5) return 0.35;
        return 0.12;
      case OmisuScreensaverEffect.blackhole:
        if (phase < 0.35) {
          final pull = Curves.easeIn.transform(phase / 0.35);
          return 1.0 - pull * (dist / maxDist).clamp(0.0, 0.85);
        }
        if (phase < 0.55) {
          return 0.15 + 0.1 * _rng.nextDouble();
        }
        if (phase < 0.85) {
          final burst = Curves.easeOut.transform((phase - 0.55) / 0.3);
          return burst * (1 - (dist / maxDist).clamp(0.0, 1.0) * 0.5);
        }
        return Curves.easeIn.transform((phase - 0.85) / 0.15);
      case OmisuScreensaverEffect.thunderstorm:
        final flash = phase < 0.12 || (phase > 0.45 && phase < 0.52);
        return flash ? 1.0 : 0.55 + 0.25 * math.sin(phase * math.pi * 4);
      case OmisuScreensaverEffect.decrypt:
        return 0.85;
      case OmisuScreensaverEffect.matrix:
        return 0.7 + 0.3 * ((col + row) % 3) / 3;
      default:
        return 1.0;
    }
  }

  Offset _resolveOffset(
    double dx,
    double dy,
    double dist,
    double maxDist,
    int row,
    int col,
  ) {
    switch (effect) {
      case OmisuScreensaverEffect.wave:
        return Offset(0, math.sin(wave * math.pi * 2 + col * 0.15) * 3);
      case OmisuScreensaverEffect.glitch:
        final jitter = glitch < 0.5 ? (glitch * 10 - 2) : ((1 - glitch) * 10 - 2);
        if ((row + col) % 3 == 0) return Offset(jitter, 0);
        return Offset.zero;
      case OmisuScreensaverEffect.blackhole:
        if (phase < 0.35) {
          final pull = Curves.easeIn.transform(phase / 0.35);
          return Offset(-dx * pull * 0.92, -dy * pull * 0.92);
        }
        if (phase < 0.55) {
          return Offset(
            (_rng.nextDouble() - 0.5) * 4,
            (_rng.nextDouble() - 0.5) * 4,
          );
        }
        if (phase < 0.85) {
          final burst = Curves.easeOut.transform((phase - 0.55) / 0.3);
          return Offset(dx * burst * 0.35, dy * burst * 0.35);
        }
        return Offset.zero;
      case OmisuScreensaverEffect.thunderstorm:
        final slice = (row ~/ 2) % 2 == 0;
        final shake = math.sin(phase * math.pi * 16) * (slice ? 3.0 : 1.5);
        return Offset(shake, 0);
      case OmisuScreensaverEffect.matrix:
        final drift = math.sin(phase * math.pi * 2 + col * 0.2) * 1.5;
        return Offset(0, drift - phase * 6);
      default:
        return Offset.zero;
    }
  }

  Color _resolveColor(double alpha) {
    var fg = color.withValues(alpha: color.a * alpha);

    if (effect == OmisuScreensaverEffect.matrix) {
      fg = Color.lerp(
            const Color(0xFF9ECE6A),
            color,
            0.35,
          )?.withValues(alpha: color.a * alpha) ??
          fg;
    }

    if (effect == OmisuScreensaverEffect.shimmer) {
      final band = 1.0 - (shimmer - 0.5).abs() * 2;
      final boost = band.clamp(0.0, 1.0) * 0.45;
      fg = Color.lerp(fg, Colors.white, boost) ?? fg;
    }

    if (effect == OmisuScreensaverEffect.thunderstorm && phase < 0.12) {
      fg = Color.lerp(fg, Colors.white, 0.65) ?? fg;
    }

    return fg;
  }

  @override
  bool shouldRepaint(covariant OmisuScreensaverEffectPainter old) {
    return old.lines != lines ||
        old.color != color ||
        old.fontSize != fontSize ||
        old.effect != effect ||
        old.phase != phase ||
        old.shimmer != shimmer ||
        old.wave != wave ||
        old.pulse != pulse ||
        old.glitch != glitch;
  }
}

/// Computes a compact font size for the block-art grid.
double omisuScreensaverFontSize({
  required Size screenSize,
  required List<String> lines,
  double maxWidthFraction = 0.38,
  double maxHeightFraction = 0.22,
  double maxFontSize = 20,
  double minFontSize = 6,
}) {
  if (lines.isEmpty) return maxFontSize;

  final maxChars = lines.fold<int>(0, (a, b) => math.max(a, b.length));
  final maxW = screenSize.width * maxWidthFraction;
  final maxH = screenSize.height * maxHeightFraction;
  final fromWidth = maxW / (maxChars * 0.58);
  final fromHeight = maxH / (lines.length * 0.92);
  return math.min(maxFontSize, math.max(minFontSize, math.min(fromWidth, fromHeight)));
}
