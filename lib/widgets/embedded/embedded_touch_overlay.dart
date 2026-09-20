import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/widgets/embedded/embedded_touch_layout.dart';

/// On-screen gamepad for touch-only devices during embedded play.
///
/// Button sets adapt to the active console ([systemId]).
class EmbeddedTouchOverlay extends StatelessWidget {
  const EmbeddedTouchOverlay({
    super.key,
    required this.systemId,
  });

  final String systemId;

  @override
  Widget build(BuildContext context) {
    final layout = EmbeddedTouchLayoutConfig.forSystem(systemId);
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            left: 12.r,
            bottom: 24.r,
            child: _DpadCluster(),
          ),
          if (layout.faceLayout == TouchFaceLayout.n64)
            Positioned(
              left: 140.r,
              bottom: 36.r,
              child: _CButtonCluster(),
            ),
          Positioned(
            right: 12.r,
            bottom: 24.r,
            child: _FaceButtonCluster(layout: layout),
          ),
          if (layout.showShoulders && layout.faceLayout != TouchFaceLayout.n64)
            Positioned(
              right: 12.r,
              bottom: 168.r,
              child: _ShoulderRow(showTriggers: layout.showTriggers),
            ),
          if (layout.faceLayout == TouchFaceLayout.n64)
            Positioned(
              right: 12.r,
              bottom: 200.r,
              child: _N64TopRow(),
            ),
          if (layout.showStart || layout.showSelect)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8.r,
              child: _MenuRow(
                showStart: layout.showStart,
                showSelect: layout.showSelect,
              ),
            ),
        ],
      ),
    );
  }

  static void _sendDown(int keyCode) {
    EmbeddedEmulatorService.sendKeyEvent(
      action: EmbeddedEmulatorService.keyActionDown,
      keyCode: keyCode,
    );
  }

  static void _sendUp(int keyCode) {
    EmbeddedEmulatorService.sendKeyEvent(
      action: EmbeddedEmulatorService.keyActionUp,
      keyCode: keyCode,
    );
  }
}

class _DpadCluster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _TouchButton(
              label: '↑',
              size: size,
              onDown: () => EmbeddedTouchOverlay._sendDown(
                EmbeddedEmulatorService.keyDpadUp,
              ),
              onUp: () => EmbeddedTouchOverlay._sendUp(
                EmbeddedEmulatorService.keyDpadUp,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _TouchButton(
              label: '←',
              size: size,
              onDown: () => EmbeddedTouchOverlay._sendDown(
                EmbeddedEmulatorService.keyDpadLeft,
              ),
              onUp: () => EmbeddedTouchOverlay._sendUp(
                EmbeddedEmulatorService.keyDpadLeft,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _TouchButton(
              label: '→',
              size: size,
              onDown: () => EmbeddedTouchOverlay._sendDown(
                EmbeddedEmulatorService.keyDpadRight,
              ),
              onUp: () => EmbeddedTouchOverlay._sendUp(
                EmbeddedEmulatorService.keyDpadRight,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TouchButton(
              label: '↓',
              size: size,
              onDown: () => EmbeddedTouchOverlay._sendDown(
                EmbeddedEmulatorService.keyDpadDown,
              ),
              onUp: () => EmbeddedTouchOverlay._sendUp(
                EmbeddedEmulatorService.keyDpadDown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceButtonCluster extends StatelessWidget {
  const _FaceButtonCluster({required this.layout});

  final EmbeddedTouchLayoutConfig layout;

  @override
  Widget build(BuildContext context) {
    switch (layout.faceLayout) {
      case TouchFaceLayout.nintendo2:
        return _Nintendo2Face();
      case TouchFaceLayout.nintendo4:
        return _Nintendo4Face();
      case TouchFaceLayout.genesis3:
        return _Genesis3Face();
      case TouchFaceLayout.genesis6:
        return _Genesis6Face();
      case TouchFaceLayout.playstation:
        return _PlayStationFace();
      case TouchFaceLayout.n64:
        return _N64Face();
      case TouchFaceLayout.arcade4:
        return _Arcade4Face();
    }
  }
}

class _Nintendo2Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 56.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _faceButton('B', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
        SizedBox(height: 8.r),
        _faceButton('A', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
      ],
    );
  }
}

class _Nintendo4Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 50.r;
    return SizedBox(
      width: size * 2.6,
      height: size * 2.6,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _faceButton('X', EmbeddedEmulatorService.keyButtonX, size, 0xFF64B5F6),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _faceButton('Y', EmbeddedEmulatorService.keyButtonY, size, 0xFFFFB74D),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _faceButton('A', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _faceButton('B', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
          ),
        ],
      ),
    );
  }
}

class _Genesis3Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 50.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _faceButton('C', EmbeddedEmulatorService.keyButtonY, size, 0xFFBA68C8),
        SizedBox(height: 6.r),
        _faceButton('B', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
        SizedBox(height: 6.r),
        _faceButton('A', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
      ],
    );
  }
}

class _Genesis6Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _faceButton('X', EmbeddedEmulatorService.keyButtonX, size, 0xFF64B5F6),
            SizedBox(width: 6.r),
            _faceButton('Y', EmbeddedEmulatorService.keyButtonY, size, 0xFFFFB74D),
            SizedBox(width: 6.r),
            _faceButton('Z', EmbeddedEmulatorService.keyButtonL2, size, 0xFF90A4AE),
          ],
        ),
        SizedBox(height: 6.r),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _faceButton('A', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
            SizedBox(width: 6.r),
            _faceButton('B', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
            SizedBox(width: 6.r),
            _faceButton('C', EmbeddedEmulatorService.keyButtonR2, size, 0xFFBA68C8),
          ],
        ),
      ],
    );
  }
}

class _PlayStationFace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 48.r;
    return SizedBox(
      width: size * 2.6,
      height: size * 2.6,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _faceButton('△', EmbeddedEmulatorService.keyButtonX, size, 0xFF81C784),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _faceButton('□', EmbeddedEmulatorService.keyButtonY, size, 0xFF64B5F6),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _faceButton('○', EmbeddedEmulatorService.keyButtonA, size, 0xFFE57373),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _faceButton('✕', EmbeddedEmulatorService.keyButtonB, size, 0xFFFFB74D),
          ),
        ],
      ),
    );
  }
}

class _N64Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 52.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _faceButton('B', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
        SizedBox(height: 8.r),
        _faceButton('A', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
      ],
    );
  }
}

class _CButtonCluster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 38.r;
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _faceButton('C↑', EmbeddedEmulatorService.keyButtonX, size, 0xFFFFCC80),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _faceButton('C←', EmbeddedEmulatorService.keyButtonL1, size, 0xFFFFCC80),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _faceButton('C→', EmbeddedEmulatorService.keyButtonR1, size, 0xFFFFCC80),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _faceButton('C↓', EmbeddedEmulatorService.keyButtonY, size, 0xFFFFCC80),
          ),
        ],
      ),
    );
  }
}

class _N64TopRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _faceButton('L', EmbeddedEmulatorService.keyButtonL2, size, 0xFFB0BEC5),
        SizedBox(width: 8.r),
        _faceButton('Z', EmbeddedEmulatorService.keyButtonR2, size, 0xFF90A4AE),
        SizedBox(width: 8.r),
        _faceButton('R', EmbeddedEmulatorService.keyButtonR1, size, 0xFFB0BEC5),
        SizedBox(width: 8.r),
        _menuButton('Start', EmbeddedEmulatorService.keyButtonStart, size),
      ],
    );
  }
}

class _Arcade4Face extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 48.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _faceButton('3', EmbeddedEmulatorService.keyButtonX, size, 0xFF64B5F6),
            SizedBox(width: 8.r),
            _faceButton('4', EmbeddedEmulatorService.keyButtonY, size, 0xFFFFB74D),
          ],
        ),
        SizedBox(height: 8.r),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _faceButton('1', EmbeddedEmulatorService.keyButtonA, size, 0xFF81C784),
            SizedBox(width: 8.r),
            _faceButton('2', EmbeddedEmulatorService.keyButtonB, size, 0xFFE57373),
          ],
        ),
      ],
    );
  }
}

class _ShoulderRow extends StatelessWidget {
  const _ShoulderRow({required this.showTriggers});

  final bool showTriggers;

  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shoulderButton('L', EmbeddedEmulatorService.keyButtonL1, size),
            SizedBox(width: 48.r),
            _shoulderButton('R', EmbeddedEmulatorService.keyButtonR1, size),
          ],
        ),
        if (showTriggers) ...[
          SizedBox(height: 6.r),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shoulderButton('L2', EmbeddedEmulatorService.keyButtonL2, size * 0.9),
              SizedBox(width: 40.r),
              _shoulderButton('R2', EmbeddedEmulatorService.keyButtonR2, size * 0.9),
            ],
          ),
        ],
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.showStart,
    required this.showSelect,
  });

  final bool showStart;
  final bool showSelect;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (showSelect) {
      children.add(
        _menuButton('Select', EmbeddedEmulatorService.keyButtonSelect, 52.r),
      );
    }
    if (showSelect && showStart) {
      children.add(SizedBox(width: 12.r));
    }
    if (showStart) {
      children.add(
        _menuButton('Start', EmbeddedEmulatorService.keyButtonStart, 52.r),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

Widget _faceButton(String label, int keyCode, double size, int color) {
  return _TouchButton(
    label: label,
    size: size,
    color: Color(color),
    onDown: () => EmbeddedTouchOverlay._sendDown(keyCode),
    onUp: () => EmbeddedTouchOverlay._sendUp(keyCode),
  );
}

Widget _shoulderButton(String label, int keyCode, double size) {
  return _TouchButton(
    label: label,
    size: size,
    color: const Color(0xFFB0BEC5),
    onDown: () => EmbeddedTouchOverlay._sendDown(keyCode),
    onUp: () => EmbeddedTouchOverlay._sendUp(keyCode),
  );
}

Widget _menuButton(String label, int keyCode, double size) {
  return _TouchButton(
    label: label,
    size: size,
    onDown: () => EmbeddedTouchOverlay._sendDown(keyCode),
    onUp: () => EmbeddedTouchOverlay._sendUp(keyCode),
  );
}

class _TouchButton extends StatefulWidget {
  const _TouchButton({
    required this.label,
    required this.size,
    required this.onDown,
    required this.onUp,
    this.color,
  });

  final String label;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final Color? color;

  @override
  State<_TouchButton> createState() => _TouchButtonState();
}

class _TouchButtonState extends State<_TouchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? Colors.white.withValues(alpha: 0.22);
    final fill = _pressed ? base.withValues(alpha: 0.55) : base;
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onPointerCancel: (_) {
        if (_pressed) {
          setState(() => _pressed = false);
          widget.onUp();
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.size * 0.28,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
