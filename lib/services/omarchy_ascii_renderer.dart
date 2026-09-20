import 'dart:convert';

import 'package:flutter/services.dart';

/// Renders text in Omarchy's Delta Corps Priest 1 block font (letters + spaces).
///
/// Matches [`omarchy-ascii`](omarchy-quattro/bin/omarchy-ascii) kerning rules.
/// Digits and punctuation are stripped, same as Omarchy.
class OmarchyAsciiRenderer {
  OmarchyAsciiRenderer._();

  static final OmarchyAsciiRenderer instance = OmarchyAsciiRenderer._();

  static const int _maxLabelLength = 16;
  static const int _cacheMax = 48;

  _FontData? _font;
  final Map<String, List<String>> _cache = {};

  /// Sanitize for FIGlet: uppercase letters and spaces only.
  static String sanitize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ' || (rune >= 0x41 && rune <= 0x5A)) {
        buffer.write(ch);
      }
    }
    return buffer.toString().replaceAll(RegExp(r' +'), ' ').trim();
  }

  /// Shorten long titles before rendering.
  static String truncate(String sanitized) {
    if (sanitized.length <= _maxLabelLength) return sanitized;
    return sanitized.substring(0, _maxLabelLength).trimRight();
  }

  Future<void> ensureLoaded() async {
    if (_font != null) return;
    final raw = await rootBundle.loadString(
      'assets/ascii/delta_corps_priest_1.json',
    );
    _font = _FontData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Render [text] to block-art lines. Returns empty when nothing drawable.
  Future<List<String>> render(String text) async {
    await ensureLoaded();
    final font = _font!;
    final sanitized = truncate(sanitize(text));
    if (sanitized.isEmpty) return const [];

    final cached = _cache[sanitized];
    if (cached != null) return cached;

    final lines = font.draw(sanitized);
    if (_cache.length >= _cacheMax) {
      _cache.remove(_cache.keys.first);
    }
    _cache[sanitized] = lines;
    return lines;
  }

  /// Synchronous render after [ensureLoaded] has completed.
  List<String> renderSync(String text) {
    final font = _font;
    if (font == null) return const [];
    final sanitized = truncate(sanitize(text));
    if (sanitized.isEmpty) return const [];

    final cached = _cache[sanitized];
    if (cached != null) return cached;

    final lines = font.draw(sanitized);
    if (_cache.length >= _cacheMax) {
      _cache.remove(_cache.keys.first);
    }
    _cache[sanitized] = lines;
    return lines;
  }
}

class _FontData {
  _FontData({
    required this.height,
    required this.glyphs,
    required this.widths,
  });

  factory _FontData.fromJson(Map<String, dynamic> json) {
    final glyphMap = <String, List<String>>{};
    final rawGlyphs = json['glyphs'] as Map<String, dynamic>;
    for (final entry in rawGlyphs.entries) {
      glyphMap[entry.key] = (entry.value as List<dynamic>)
          .map((e) => e as String)
          .toList();
    }
    final widthMap = <String, int>{};
    final rawWidths = json['widths'] as Map<String, dynamic>;
    for (final entry in rawWidths.entries) {
      widthMap[entry.key] = entry.value as int;
    }
    return _FontData(
      height: json['height'] as int? ?? 8,
      glyphs: glyphMap,
      widths: widthMap,
    );
  }

  final int height;
  final Map<String, List<String>> glyphs;
  final Map<String, int> widths;

  String _glyphKey(String ch) => ch == ' ' ? 'SPACE' : ch;

  List<String> draw(String source) {
    final out = List<String>.filled(height, '');
    final trail = List<int>.filled(height, 0);
    var drew = false;

    for (var i = 0; i < source.length; i++) {
      final ch = source[i];
      final key = _glyphKey(ch);
      final glyphLines = glyphs[key];
      final glyphWidth = widths[key] ?? 0;
      if (glyphLines == null || glyphWidth == 0) continue;

      final piece = List<String>.generate(height, (r) {
        final line = r < glyphLines.length ? glyphLines[r] : '';
        return line.padRight(glyphWidth);
      });

      if (!drew) {
        for (var r = 0; r < height; r++) {
          out[r] = _rtrim(piece[r]);
          trail[r] = glyphWidth - out[r].length;
        }
        drew = true;
        continue;
      }

      var amount = -1;
      for (var r = 0; r < height; r++) {
        final lead = glyphWidth - _ltrim(piece[r]).length;
        final candidate = trail[r] + lead;
        if (amount < 0 || candidate < amount) {
          amount = candidate;
        }
      }

      for (var r = 0; r < height; r++) {
        final cut = amount < trail[r] ? amount : trail[r];
        final keep = amount - cut;
        final remaining = trail[r] - cut;
        final fragment = piece[r].substring(
          keep.clamp(0, piece[r].length),
        );
        final body = _rtrim(fragment);

        if (body.isEmpty) {
          trail[r] = remaining + fragment.length;
        } else {
          final pad = remaining > 0 ? ' ' * remaining : '';
          out[r] = out[r] + pad + body;
          trail[r] = fragment.length - body.length;
        }
      }
    }

    if (!drew) return const [];
    return out.map(_rtrim).toList();
  }

  static String _rtrim(String s) => s.replaceAll(RegExp(r' +$'), '');

  static String _ltrim(String s) => s.replaceFirst(RegExp(r'^ +'), '');
}
