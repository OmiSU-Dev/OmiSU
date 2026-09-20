import 'package:flutter/material.dart';

import 'omisu/omisu_ascii_logo.dart';

/// The OmiSU ASCII wordmark with a soft light band sweeping across it.
///
/// Used as the minimal startup indicator while the initial config is applied
/// and the ROM scan runs. The glint travels over the mono glyph via a
/// [ShaderMask] in [BlendMode.srcATop], which paints the moving gradient only
/// where the text has pixels.
///
/// With [progress] set, the glint's position tracks that value — the shine
/// crosses the logo exactly in step with the scan. With it null, the glint
/// sweeps on its own on a repeating cycle.
class ShimmeringLogo extends StatefulWidget {
  const ShimmeringLogo({super.key, this.width = 280, this.progress});

  /// Rendered width of the wordmark; height follows [OmisuAsciiLogo.splashAspectRatio].
  final double width;

  /// Glint position, 0.0 (off the left edge) to 1.0 (off the right edge).
  /// Null selects the ambient self-paced sweep.
  final double? progress;

  @override
  State<ShimmeringLogo> createState() => _ShimmeringLogoState();
}

class _ShimmeringLogoState extends State<ShimmeringLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Sweep position the glint is actually drawn at, republished from
  /// [_controller] at a capped rate. See [_publishSweep].
  final ValueNotifier<double> _sweep = ValueNotifier<double>(0);

  /// Sweep travel required before the glint is redrawn.
  ///
  /// The controller spans the whole sweep over two seconds, so this is about
  /// one 60 Hz frame's worth of movement, or roughly 2% of the logo's width.
  static const double _minSweepDelta = 0.0075;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _controller.addListener(_publishSweep);
    final progress = widget.progress;
    if (progress == null) {
      _controller.repeat();
    } else {
      _controller.value = progress.clamp(0.0, 1.0);
    }
  }

  /// Republishes the controller's position to [_sweep] once the glint has
  /// moved far enough to be worth redrawing.
  void _publishSweep() {
    final double value = _controller.value;
    if (_controller.isAnimating &&
        (value - _sweep.value).abs() < _minSweepDelta) {
      return;
    }
    _sweep.value = value;
  }

  @override
  void didUpdateWidget(ShimmeringLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    final progress = widget.progress;
    if (progress != null) {
      _controller.stop();
      _controller.animateTo(
        progress.clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else if (oldWidget.progress != null) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_publishSweep);
    _controller.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const glint = Colors.white;
    final clear = glint.withValues(alpha: 0.0);
    final shine = glint.withValues(alpha: 0.55);

    return ValueListenableBuilder<double>(
      valueListenable: _sweep,
      builder: (context, sweep, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.4),
              end: const Alignment(1.0, 0.4),
              colors: [clear, clear, shine, clear, clear],
              stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
              transform: _SlidingGradientTransform(sweep),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: OmisuAsciiLogo(
        width: widget.width,
        showBootPrompt: false,
      ),
    );
  }
}

/// Slides the shine band across the glyph, 0 → fully off the left edge,
/// 1 → fully off the right edge.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (progress * 3.2 - 1.6);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
