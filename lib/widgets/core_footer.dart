import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/utils/color.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:omisu/l10n/app_locale.dart';

import '../themes/corner_radii.dart';
import '../themes/omisu_accent.dart';

/// Visual role for footer / gamepad action chips.
enum GamepadControlRole { secondary, primary }

/// Height of every [CoreFooter] strip, in logical (pre-`.r`) units.
///
/// Exposed so screens that float the footer over their content can pad the
/// scrollable by exactly the strip it sits on.
const double kCoreFooterHeight = 42;

/// Base footer class that eliminates duplicated code between games_footer and systems_footer.
abstract class CoreFooter extends StatefulWidget {
  const CoreFooter({super.key});

  /// Subclasses must implement this to define their controls (buttons).
  List<Widget> buildControls(BuildContext context);

  /// Optional left-side content (e.g. app name, system name).
  Widget? buildLeftContent(BuildContext context) => null;

  /// Whether controls should be centered (true) or right-aligned (false).
  bool get centerControls => true;

  /// Whether to show the app version (useful for hiding it in dense footers).
  bool get showVersion => centerControls;

  @override
  State<CoreFooter> createState() => _CoreFooterState();
}

class _CoreFooterState extends State<CoreFooter> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'v1.0.0'; // Fallback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kCoreFooterHeight.r,
      decoration: BoxDecoration(
        color: widget.centerControls
            ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5)
            : Colors.transparent,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.r),
      child: widget.centerControls
          ? _buildCenteredLayout()
          : _buildSplitLayout(),
    );
  }

  Widget _buildCenteredLayout() {
    return Stack(
      children: [
        // Centered controls
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.buildControls(context),
          ),
        ),
        // Version label on the right
        if (widget.showVersion && _appVersion.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '${AppLocale.beta.getString(context)} $_appVersion',
                style: TextStyle(
                  fontSize: 12.r,
                  fontFamily: OmisuAccent.fontFamily,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.3.r,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplitLayout() {
    return Row(
      children: [
        // Left content
        Expanded(child: widget.buildLeftContent(context) ?? const SizedBox()),
        // Controls on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.buildControls(context),
        ),
      ],
    );
  }
}

/// Shared gamepad controls widget used by both footers.
class GamepadControl extends StatelessWidget {
  final dynamic iconPath; // Can be a String (asset path) or IconData
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final GamepadControlRole role;

  const GamepadControl({
    super.key,
    this.iconPath,
    required this.label,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.role = GamepadControlRole.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveRole = backgroundColor == scheme.tertiary
        ? GamepadControlRole.primary
        : backgroundColor == scheme.tertiaryFixed
        ? GamepadControlRole.secondary
        : role;
    final isPrimary = effectiveRole == GamepadControlRole.primary;

    final useLegacyBg =
        OmisuAccent.isLegacyFooterBackground(backgroundColor, scheme);
    final useLegacyText = OmisuAccent.isLegacyFooterText(textColor, scheme);

    final BoxDecoration decoration;
    final Color contentColor;

    if (gradient != null) {
      decoration = BoxDecoration(
        gradient: gradient,
        borderRadius:
            theme.extension<CornerRadii>()?.radiusInternal ??
            BorderRadius.circular(8.r),
        border: Border.all(
          color: OmisuAccent.focusGradient[0].withValues(alpha: 0.4),
          width: 1.r,
        ),
      );
      contentColor = textColor ?? OmisuAccent.primaryActionForeground(context);
    } else if (isPrimary && (backgroundColor == null || useLegacyBg)) {
      decoration = OmisuAccent.primaryActionDecoration(context).copyWith(
        borderRadius:
            theme.extension<CornerRadii>()?.radiusInternal ??
            BorderRadius.circular(8.r),
      );
      contentColor = useLegacyText || textColor == null
          ? OmisuAccent.primaryActionForeground(context)
          : textColor!;
    } else if (!isPrimary && (backgroundColor == null || useLegacyBg)) {
      decoration = OmisuAccent.secondaryActionDecoration(context).copyWith(
        borderRadius:
            theme.extension<CornerRadii>()?.radiusInternal ??
            BorderRadius.circular(8.r),
      );
      contentColor = useLegacyText || textColor == null
          ? OmisuAccent.secondaryActionForeground(context)
          : textColor!;
    } else {
      final buttonBg =
          backgroundColor ?? scheme.onSurface.withValues(alpha: 0.1);
      contentColor = textColor ?? scheme.onPrimary;
      decoration = BoxDecoration(
        color: buttonBg,
        borderRadius:
            theme.extension<CornerRadii>()?.radiusInternal ??
            BorderRadius.circular(8.r),
        border: Border.all(color: lightenColor(buttonBg, 0.05), width: 1.r),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(2.0.r, 2.0.r),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        splashColor: contentColor.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        borderRadius:
            theme.extension<CornerRadii>()?.radiusInternal ??
            BorderRadius.circular(8.r),

        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 5.r),
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, size: 12.r, color: contentColor)
              else if (iconPath is String)
                SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: Image.asset(
                    iconPath,
                    color: contentColor,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              SizedBox(width: 5.r),
              Text(
                label,
                style: TextStyle(
                  fontFamily: OmisuAccent.fontFamily,
                  fontSize: 11.r,
                  color: contentColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
              SizedBox(width: 2.r),
            ],
          ),
        ),
      ),
    );
  }
}
