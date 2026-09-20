import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omisu/providers/omisu_shell_provider.dart';
import 'package:omisu/services/menu_ambient_service.dart';
import 'package:omisu/services/omarchy_ascii_renderer.dart';
import 'package:omisu/themes/ambient_chrome.dart';
import 'package:omisu/widgets/omisu/omisu_ascii_logo.dart';
import 'package:omisu/widgets/omisu/omisu_screensaver_effects.dart';
import 'package:provider/provider.dart';

/// Omarchy-style animated ASCII backdrop for the home menu shell.
class OmisuScreensaverBackdrop extends StatefulWidget {
  const OmisuScreensaverBackdrop({super.key, this.opacity = 0.72});

  final double opacity;

  /// Horizontal share of screen for block art (kept modest for grid readability).
  static const double maxWidthFraction = 0.38;

  /// Vertical share — prevents tall titles from dominating the panel.
  static const double maxHeightFraction = 0.22;

  static const double maxFontSize = 20;

  @override
  State<OmisuScreensaverBackdrop> createState() =>
      _OmisuScreensaverBackdropState();
}

class _OmisuScreensaverBackdropState extends State<OmisuScreensaverBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _effectHold;
  late final AnimationController _effectPhase;
  late final AnimationController _shimmer;
  late final AnimationController _wave;
  late final AnimationController _pulse;
  late final AnimationController _glitch;
  late final AnimationController _crossFade;

  List<String> _lines = OmisuAsciiLogo.screensaverArt;
  String _lastLabel = '\u0000';
  bool _fontReady = false;
  OmisuScreensaverEffect _effect = OmisuScreensaverEffect.sweep;
  final math.Random _random = math.Random();
  OmisuShellProvider? _shell;

  @override
  void initState() {
    super.initState();
    _effectHold = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pickNextEffect();
          _effectHold.forward(from: 0);
        }
      });

    _effectPhase = AnimationController(
      vsync: this,
      duration: _effect.cycleDuration,
    )..repeat();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _glitch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _crossFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );

    _effectHold.forward();
    OmarchyAsciiRenderer.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() => _fontReady = true);
      _refreshLines(_shell?.focusAsciiLabel);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shell = context.read<OmisuShellProvider>();
    if (_shell == shell) return;
    _shell?.removeListener(_onShellChanged);
    _shell = shell;
    _shell!.addListener(_onShellChanged);
    _onShellChanged();
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShellChanged);
    _effectHold.dispose();
    _effectPhase.dispose();
    _shimmer.dispose();
    _wave.dispose();
    _pulse.dispose();
    _glitch.dispose();
    _crossFade.dispose();
    super.dispose();
  }

  void _onShellChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshLines(_shell?.focusAsciiLabel);
    });
  }

  void _pickNextEffect() {
    const pool = OmisuScreensaverEffect.values;
    OmisuScreensaverEffect next;
    do {
      next = pool[_random.nextInt(pool.length)];
    } while (next == _effect && pool.length > 1);

    setState(() => _effect = next);
    _effectPhase
      ..duration = next.cycleDuration
      ..repeat();

    if (next == OmisuScreensaverEffect.glitch) {
      _glitch.repeat();
    } else if (_glitch.isAnimating) {
      _glitch.stop();
    }
  }

  Future<void> _refreshLines(String? label) async {
    final sanitized = label == null || label.isEmpty
        ? ''
        : OmarchyAsciiRenderer.truncate(
            OmarchyAsciiRenderer.sanitize(label),
          );

    final cacheKey = sanitized.isEmpty ? '__OMISU__' : sanitized;
    if (cacheKey == _lastLabel) return;
    _lastLabel = cacheKey;

    List<String> next;
    if (!_fontReady || sanitized.isEmpty) {
      next = OmisuAsciiLogo.screensaverArt;
    } else {
      await OmarchyAsciiRenderer.instance.ensureLoaded();
      next = OmarchyAsciiRenderer.instance.renderSync(sanitized);
      if (next.isEmpty) {
        next = OmisuAsciiLogo.screensaverArt;
      }
    }

    if (!mounted) return;
    setState(() => _lines = next);
    await _crossFade.animateTo(0, curve: Curves.easeOut);
    if (!mounted) return;
    await _crossFade.animateTo(1, curve: Curves.easeIn);
  }

  Color _glyphColor(BuildContext context) {
    final chrome = AmbientChrome.of(context);
    final theme = Theme.of(context);
    final green = OmisuAsciiLogo.brandGreen;
    if (chrome.dustSecondary == green ||
        theme.colorScheme.secondary == green) {
      return green;
    }
    return Color.lerp(chrome.dustPrimary, theme.colorScheme.primary, 0.55) ??
        chrome.dustPrimary;
  }

  @override
  Widget build(BuildContext context) {
    if (MenuAmbientService.instance.isPausedForGame) {
      return const SizedBox.shrink();
    }

    final screen = MediaQuery.sizeOf(context);
    final color = _glyphColor(context).withValues(alpha: widget.opacity);
    final fontSize = omisuScreensaverFontSize(
      screenSize: screen,
      lines: _lines,
      maxWidthFraction: OmisuScreensaverBackdrop.maxWidthFraction,
      maxHeightFraction: OmisuScreensaverBackdrop.maxHeightFraction,
      maxFontSize: OmisuScreensaverBackdrop.maxFontSize,
    );
    final boxW = screen.width * OmisuScreensaverBackdrop.maxWidthFraction;
    final boxH = screen.height * OmisuScreensaverBackdrop.maxHeightFraction;

    return FadeTransition(
      opacity: _crossFade,
      child: Center(
        child: SizedBox(
          width: boxW,
          height: boxH,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _effectPhase,
              _shimmer,
              _wave,
              _pulse,
              _glitch,
            ]),
            builder: (context, _) {
              return CustomPaint(
                painter: OmisuScreensaverEffectPainter(
                  lines: _lines,
                  color: color,
                  fontSize: fontSize,
                  effect: _effect,
                  phase: _effectPhase.value,
                  shimmer: _shimmer.value,
                  wave: _wave.value,
                  pulse: _pulse.value,
                  glitch: _glitch.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
