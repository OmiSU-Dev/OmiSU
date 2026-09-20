import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// OmiSU wordmark styles aligned with Omarchy screensaver / boot branding.
enum OmisuLogoStyle {
  /// Delta Corps Priest 1 block art (Omarchy screensaver default).
  screensaver,

  /// Small boxed mark for tight headers.
  badge,

  /// Single-line HUD chip.
  compact,
}

/// Omarchy-style OmiSU ASCII logo for splash, screensaver, and HUD chrome.
///
/// The screensaver variant uses the same block glyphs as Omarchy's
/// `logo.txt` / Delta Corps Priest 1 FIGlet output. JetBrains Mono Nerd Font
/// renders █ ▀ ▄ correctly at tight line height — unlike the old boxed
/// 7-bit wordmark.
class OmisuAsciiLogo extends StatelessWidget {
  const OmisuAsciiLogo({
    super.key,
    this.width,
    this.style = OmisuLogoStyle.screensaver,
    this.compact = false,
    this.color,
    this.lineHeight,
    this.bootLine,
    this.showBootPrompt = true,
  });

  /// Target width in logical pixels. Height follows [aspectRatio].
  final double? width;

  /// Preferred style. [compact] overrides to [OmisuLogoStyle.compact].
  final OmisuLogoStyle style;

  /// Legacy flag — maps to [OmisuLogoStyle.compact].
  final bool compact;

  final Color? color;

  /// When null, uses a style-tuned default (tighter for block art).
  final double? lineHeight;

  /// Terminal prompt under the wordmark, e.g. `> boot_`.
  final String? bootLine;

  /// When false, omits the prompt line (About page, secondary display).
  final bool showBootPrompt;

  /// Omarchy traditional brand green (Limine `interface_branding_colour`).
  static const Color brandGreen = Color(0xFF9ECE6A);

  /// Omarchy screensaver block art — generated via Omarchy Delta Corps Priest 1.
  static const List<String> screensaverArt = [
    ' ▄██████▄    ▄▄▄▄███▄▄▄▄    ▄█     ▄████████ ███    █▄',
    '███    ███ ▄██▀▀▀███▀▀▀██▄ ███    ███    ███ ███    ███',
    '███    ███ ███   ███   ███ ███▌   ███    █▀  ███    ███',
    '███    ███ ███   ███   ███ ███▌   ███        ███    ███',
    '███    ███ ███   ███   ███ ███▌ ▀███████████ ███    ███',
    '███    ███ ███   ███   ███ ███           ███ ███    ███',
    '███    ███ ███   ███   ███ ███     ▄█    ███ ███    ███',
    ' ▀██████▀   ▀█   ███   █▀  █▀    ▄████████▀  ████████▀',
  ];

  static const List<String> _badgeLinesPrefix = [
    '0x4F4D495355 ; OMISU',
    '+===========================+',
    '|       O  M  i  S  U       |',
    '+===========================+',
  ];

  static const String _defaultBootLine = '> boot_';
  static const List<String> _compactLines = ['OMISU>'];

  OmisuLogoStyle get _resolvedStyle =>
      compact ? OmisuLogoStyle.compact : style;

  int get _lineCount {
    return switch (_resolvedStyle) {
      OmisuLogoStyle.screensaver =>
        screensaverArt.length + (showBootPrompt ? 1 : 0),
      OmisuLogoStyle.badge =>
        _badgeLinesPrefix.length + (showBootPrompt ? 1 : 0),
      OmisuLogoStyle.compact => _compactLines.length,
    };
  }

  int get _maxChars {
    return switch (_resolvedStyle) {
      OmisuLogoStyle.screensaver => 57,
      OmisuLogoStyle.badge => 29,
      OmisuLogoStyle.compact => 6,
    };
  }

  double get _resolvedLineHeight {
    if (lineHeight != null) return lineHeight!;
    return switch (_resolvedStyle) {
      OmisuLogoStyle.screensaver => 0.92,
      OmisuLogoStyle.badge => 1.12,
      OmisuLogoStyle.compact => 1.0,
    };
  }

  /// Rendered width : height for the splash block-art wordmark (art only).
  static const double splashAspectRatio = 57 / (8 * 0.92 * 0.58);

  /// Rendered width : height for this instance.
  double get aspectRatio {
    final lh = _resolvedLineHeight;
    return _maxChars / (_lineCount * lh * 0.58);
  }

  List<String> get _lines {
    return switch (_resolvedStyle) {
      OmisuLogoStyle.screensaver => [
        ...screensaverArt,
        if (showBootPrompt) bootLine ?? _defaultBootLine,
      ],
      OmisuLogoStyle.badge => [
        ..._badgeLinesPrefix,
        if (showBootPrompt) bootLine ?? _defaultBootLine,
      ],
      OmisuLogoStyle.compact => _compactLines,
    };
  }

  double _fontSizeForWidth(double targetWidth) {
    if (_resolvedStyle == OmisuLogoStyle.compact) return 10.5;
    return targetWidth / (_maxChars * 0.58);
  }

  @override
  Widget build(BuildContext context) {
    final fg = color ?? brandGreen;
    final targetWidth = width ?? switch (_resolvedStyle) {
      OmisuLogoStyle.compact => 88.0,
      OmisuLogoStyle.badge => 280.0,
      OmisuLogoStyle.screensaver => 420.0,
    };
    final fontSize = _fontSizeForWidth(targetWidth);
    final lh = _resolvedLineHeight;

    final text = Text(
      _lines.join('\n'),
      style: TextStyle(
        fontFamily: OmisuAccent.fontFamily,
        fontSize: _resolvedStyle == OmisuLogoStyle.compact ? fontSize.r : fontSize,
        height: lh,
        color: fg,
        fontWeight: FontWeight.w500,
        letterSpacing: _resolvedStyle == OmisuLogoStyle.compact ? 0.4 : 0,
      ),
      textAlign: TextAlign.center,
    );

    return SizedBox(
      width: targetWidth,
      height: _resolvedStyle == OmisuLogoStyle.compact
          ? null
          : targetWidth / aspectRatio,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: text,
      ),
    );
  }
}
