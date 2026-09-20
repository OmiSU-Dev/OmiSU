import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:omisu/models/ambient_backdrop_mode.dart';
import 'package:omisu/providers/omisu_shell_provider.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/screens/app_screen.dart';
import 'package:omisu/services/menu_ambient_service.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/themes/ambient_chrome.dart';
import 'package:omisu/widgets/omisu/omisu_screensaver_backdrop.dart';
import 'package:provider/provider.dart';

/// Shell backdrop: theme art + optional cheap Omarchy pixel dust / accent wash.
class OmisuShellBackground extends StatefulWidget {
  const OmisuShellBackground({super.key});

  @override
  State<OmisuShellBackground> createState() => _OmisuShellBackgroundState();
}

class _OmisuShellBackgroundState extends State<OmisuShellBackground>
    with TickerProviderStateMixin {
  late final AnimationController _wash;
  late final AnimationController _reactPulse;
  String? _lastFocusKey;

  @override
  void initState() {
    super.initState();
    _wash = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _reactPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _wash.dispose();
    _reactPulse.dispose();
    super.dispose();
  }

  bool _shouldAnimate(AmbientBackdropMode mode) {
    if (mode == AmbientBackdropMode.off) return false;
    if (!SfxService().isEnabled) return false;
    if (!SfxService.isScreenOn()) return false;
    if (MenuAmbientService.instance.isPausedForGame) return false;
    return true;
  }

  bool _showScreensaver({
    required AmbientBackdropMode mode,
    required OmisuShellProvider shell,
  }) {
    return mode == AmbientBackdropMode.screensaver &&
        shell.activeTabIndex == AppTabs.systems;
  }

  void _syncControllers({
    required AmbientBackdropMode mode,
    required OmisuShellProvider shell,
  }) {
    final animate = _shouldAnimate(mode);
    final reduce = MediaQuery.disableAnimationsOf(context);

    if (!animate || reduce || mode == AmbientBackdropMode.off) {
      _wash.stop();
      return;
    }

    if (mode == AmbientBackdropMode.subtle ||
        mode == AmbientBackdropMode.reactive ||
        mode == AmbientBackdropMode.screensaver) {
      if (!_wash.isAnimating) _wash.repeat(reverse: true);
    }

    if (mode == AmbientBackdropMode.reactive ||
        mode == AmbientBackdropMode.screensaver) {
      final key = '${shell.focusTitle}|${shell.backgroundPath}|${shell.focusAsciiLabel}';
      if (_lastFocusKey != null && _lastFocusKey != key) {
        _reactPulse.forward(from: 0);
      }
      _lastFocusKey = key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).scaffoldBackgroundColor;
    final chrome = AmbientChrome.of(context);

    return Consumer2<OmisuShellProvider, SqliteConfigProvider>(
      builder: (context, shell, config, _) {
        final mode = config.config.ambientBackdropMode;
        _syncControllers(mode: mode, shell: shell);

        final screensaver = _showScreensaver(mode: mode, shell: shell);
        final artPath = shell.backgroundPath;
        final hasArt =
            shell.homeChromeActive &&
            artPath != null &&
            artPath.isNotEmpty &&
            File(artPath).existsSync();

        final showDust = mode != AmbientBackdropMode.off;
        final showFanart = hasArt && !screensaver;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: screensaver ? Colors.black : base),
            if (screensaver && hasArt)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                    child: Image.file(
                      File(artPath),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            if (showFanart)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Image.file(
                    File(artPath),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (showFanart)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.62)),
              ),
            if (screensaver)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.05,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
            if (screensaver)
              const Positioned.fill(child: OmisuScreensaverBackdrop()),
            if (showDust)
              AnimatedBuilder(
                animation: Listenable.merge([_wash, _reactPulse]),
                builder: (context, _) {
                  final wash =
                      0.04 +
                      0.04 * (0.5 + 0.5 * math.sin(_wash.value * math.pi)) +
                      0.06 * _reactPulse.value;
                  return CustomPaint(
                    painter: _PixelDustPainter(
                      primary: chrome.dustPrimary,
                      secondary: chrome.dustSecondary,
                      density: chrome.density * (screensaver ? 0.65 : 1.0),
                      washStrength: wash,
                      reactiveBoost: _reactPulse.value,
                    ),
                  );
                },
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: screensaver ? 0.35 : (hasArt ? 0.2 : 0.1),
                    ),
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: screensaver ? 0.45 : (hasArt ? 0.28 : 0.16),
                    ),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PixelDustPainter extends CustomPainter {
  _PixelDustPainter({
    required this.primary,
    required this.secondary,
    required this.density,
    required this.washStrength,
    required this.reactiveBoost,
  });

  final Color primary;
  final Color secondary;
  final double density;
  final double washStrength;
  final double reactiveBoost;

  static final List<Offset> _pts = () {
    final rng = math.Random(82);
    return List.generate(72, (_) {
      return Offset(rng.nextDouble(), rng.nextDouble());
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final count = (40 + density * 40).round().clamp(24, 80);
    final cell = (2.0 + density * 2.0);

    // Soft corner washes (not full-screen fill).
    final washPaint = Paint()..style = PaintingStyle.fill;
    washPaint.shader = ui.Gradient.radial(
      Offset(size.width * 0.08, size.height * 0.08),
      size.shortestSide * 0.55,
      [
        primary.withValues(alpha: washStrength),
        primary.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(Offset.zero & size, washPaint);

    washPaint.shader = ui.Gradient.radial(
      Offset(size.width * 0.92, size.height * 0.9),
      size.shortestSide * 0.5,
      [
        secondary.withValues(alpha: washStrength * 0.85),
        secondary.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(Offset.zero & size, washPaint);

    final dust = Paint();
    for (var i = 0; i < count; i++) {
      final p = _pts[i];
      // Bias toward edges (Omarchy site pixel vignette).
      final edge =
          math.min(p.dx, 1 - p.dx).clamp(0.0, 0.5) +
          math.min(p.dy, 1 - p.dy).clamp(0.0, 0.5);
      final edgeFactor = (0.55 - edge).clamp(0.0, 0.55) / 0.55;
      if (edgeFactor < 0.08) continue;

      final color = i.isEven ? primary : secondary;
      final alpha =
          (0.08 + edgeFactor * 0.35 + reactiveBoost * 0.12) * density;
      dust.color = color.withValues(alpha: alpha.clamp(0.0, 0.55));
      final s = cell * (0.6 + edgeFactor);
      canvas.drawRect(
        Rect.fromLTWH(p.dx * size.width, p.dy * size.height, s, s),
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelDustPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.density != density ||
      old.washStrength != washStrength ||
      old.reactiveBoost != reactiveBoost;
}
