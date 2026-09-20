import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Actionable settings tile: a bordered card with a leading icon, a
/// title/subtitle block and a trailing control (toggle or action button).
///
/// This is the shared extraction of the Directories card chrome, reused by the
/// Tools and Systems panels so every actionable settings list renders with the
/// same background, corner radius, focus border and spacing. Richer one-off
/// rows (destructive/monospace paths in Directories) keep their bespoke layout.
class SettingsCardRow extends StatelessWidget {
  /// Leading glyph.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Secondary description; pass an empty string to omit it.
  final String subtitle;

  /// Maximum lines the subtitle may wrap to before it ellipsizes.
  final int subtitleMaxLines;

  /// Trailing control (e.g. [CustomToggleSwitch] or a SettingsActionButton).
  final Widget? trailing;

  /// Whether this row currently holds gamepad focus (drives the border and
  /// title/icon accent colour).
  final bool selected;

  /// Dims the icon/title/subtitle for unavailable rows. Does not itself block
  /// taps — pass `onTap: null` (and a disabled trailing control) to do that.
  final bool disabled;

  /// Optional extra content rendered beneath the title/subtitle row (e.g. a
  /// current-path chip).
  final Widget? belowContent;

  /// Touch handler. Gamepad selection is driven separately by the panel.
  final VoidCallback? onTap;

  const SettingsCardRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.subtitleMaxLines = 1,
    this.trailing,
    required this.selected,
    this.disabled = false,
    this.belowContent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: disabled ? 0.4 : 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 6.r),
      child: OmisuRetroPanel(
        active: selected,
        cornerRadius: 4,
        padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: foreground, size: 18.r),
                  SizedBox(width: 10.r),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: omisuRetroLabelStyle(
                            context,
                            size: 11,
                            weight: FontWeight.w700,
                            color: foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          SizedBox(height: 4.r),
                          Text(
                            subtitle,
                            style: omisuRetroLabelStyle(
                              context,
                              size: 9,
                              weight: FontWeight.w500,
                              letterSpacing: 0.15,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: disabled ? 0.25 : 0.62,
                              ),
                            ),
                            maxLines: subtitleMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: 10.r),
                    trailing!,
                  ],
                ],
              ),
              if (belowContent != null) ...[
                SizedBox(height: 8.r),
                belowContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
