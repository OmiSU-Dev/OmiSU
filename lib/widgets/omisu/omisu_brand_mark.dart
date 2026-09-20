import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/widgets/omisu/omisu_ascii_logo.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Compact OmiSU identity chip — Retro 82 / Omarchy HUD mark.
class OmisuBrandMark extends StatelessWidget {
  const OmisuBrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OmisuRetroPanel(
      cornerRadius: 3,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.r : 7.r,
        vertical: compact ? 2.r : 3.r,
      ),
      child: OmisuAsciiLogo(
        compact: true,
        width: compact ? 88.r : 96.r,
        color: OmisuAccent.brandGreen,
      ),
    );
  }
}
