// Shared layout constants for the OmiSU shell chrome (iiSU-style).
//
// Top bar: brand, shoulder hints, and status — pinned to the screen top.
// Nav dock: tab strip — pinned in the bottom footer between Y and A.
library;

import 'package:omisu/widgets/core_footer.dart' show kCoreFooterHeight;

/// Status row height (brand + LB/RB + clock/battery).
const double kOmisuTopBarHeight = 36;

/// Focused system title row under the status bar (when visible).
const double kOmisuHeaderTitleRowHeight = 30;

/// Panel rim (1px gradient border × 2) around [OmisuRetroPanel].
const double kOmisuRetroPanelVerticalRim = 2;

/// Nav dock height including the sliding synthwave underline.
///
/// Matches [OmisuTabStrip] non-compact layout: rim + padding + 34px slots +
/// 4px gap + 3px underline = 49.
const double kOmisuNavDockHeight = 49;

/// Compact nav dock height used inside the bottom footer row.
///
/// Matches [OmisuTabStrip] compact layout: rim + padding + 28px slots +
/// 2px gap + 2px underline = 38. Previously 36, which caused ~2 logical px
/// overflow (≈5px on scaled handheld screens).
const double kOmisuNavDockCompactHeight =
    kOmisuRetroPanelVerticalRim + 4 + 28 + 2 + 2;

/// Bottom footer row (Y · tabs · A).
const double kOmisuShellFooterHeight = kCoreFooterHeight;

/// Legacy aliases — prefer the constants above.
const double kOmisuHeaderTopRowHeight = kOmisuTopBarHeight;
const double kOmisuHeaderTabRowHeight = kOmisuNavDockHeight;
const double kOmisuHeaderRowHeight = kOmisuTopBarHeight;
const double kOmisuHeaderChromeHeight = kOmisuTopBarHeight;

/// @deprecated Nav dock lives in the footer; kept for callers migrating off top placement.
const double kOmisuNavDockGap = 22;

/// @deprecated Nav dock lives in the footer.
double omisuNavDockTop({required bool hasTitlePill}) {
  var top = kOmisuTopBarHeight + kOmisuNavDockGap;
  if (hasTitlePill) {
    top += kOmisuHeaderTitleRowHeight + 6;
  }
  return top;
}

/// Content inset below the top bar / optional focus title.
double omisuShellContentTopInset({required bool hasTitlePill}) {
  var top = kOmisuTopBarHeight + 10;
  if (hasTitlePill) {
    top += kOmisuHeaderTitleRowHeight + 6;
  }
  return top;
}

/// Content inset above the bottom footer chrome.
double omisuShellContentBottomInset() => kOmisuShellFooterHeight + 8;
