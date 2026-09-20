import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/app_themes.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/widgets/notification_bell.dart';
import 'package:omisu/widgets/omisu/omisu_nerd_icons.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Top-right status HUD: terminal hairline panel, mono clock, Omarchy-green
/// battery, L→R scan pulse, and the live [NotificationBell].
///
/// Visual recipe: option **3** (mono time, no clock glyph) + **4** (brand green
/// battery) + soft left→right pulse + Nerd Font retro glyphs.
class OmisuStatusHud extends StatefulWidget {
  const OmisuStatusHud({
    super.key,
    required this.clockText,
    required this.batteryLevel,
    this.batteryState,
    this.showBattery = true,
  });

  final String clockText;
  final int batteryLevel;
  final BatteryState? batteryState;
  final bool showBattery;

  @override
  State<OmisuStatusHud> createState() => _OmisuStatusHudState();
}

class _OmisuStatusHudState extends State<OmisuStatusHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  static const Duration _scanDuration = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: _scanDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _scan.stop();
      _scan.value = 0;
    } else if (!_scan.isAnimating) {
      _scan.repeat();
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  Color _batteryColor(BuildContext context) {
    final custom = AppThemes.getCustomColors(context);
    if (widget.batteryLevel < 0) return custom.batteryPower;
    if (widget.batteryLevel > 20) {
      return Theme.of(context).colorScheme.primary;
    }
    if (widget.batteryLevel > 5) return custom.batteryMedium;
    return custom.batteryLow;
  }

  bool get _charging =>
      widget.batteryState == BatteryState.charging ||
      widget.batteryState == BatteryState.full;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = omisuRetroLabelStyle(
      context,
      size: 11,
      letterSpacing: 0.65,
    );
    final batteryColor = _batteryColor(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.r),
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(2.r),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.45),
                width: 1.r,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Keep NotificationBell intact — dropdown, Select, badge, SFX.
                  const NotificationBell(retroGlyphs: true),
                  _Sep(color: muted),
                  Text(
                    widget.clockText,
                    style: labelStyle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (widget.showBattery) ...[
                    _Sep(color: muted),
                    Icon(
                      OmisuNerdIcons.batteryForLevel(
                        widget.batteryLevel,
                        charging: _charging,
                      ),
                      color: batteryColor,
                      size: 13.r,
                    ),
                    SizedBox(width: 3.r),
                    Text(
                      '${widget.batteryLevel}%',
                      style: labelStyle.copyWith(
                        color: batteryColor,
                        fontSize: 10.r,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MediaQuery.disableAnimationsOf(context)
                  ? const SizedBox.shrink()
                  : AnimatedBuilder(
                      animation: _scan,
                      builder: (context, child) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final band = constraints.maxWidth * 0.34;
                            final x =
                                (_scan.value *
                                    (constraints.maxWidth + band)) -
                                band;
                            return Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: x,
                                  top: 0,
                                  bottom: 0,
                                  width: band,
                                  child: child!,
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.18),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.r),
      child: Text(
        '|',
        style: TextStyle(
          fontFamily: OmisuAccent.fontFamily,
          fontSize: 10.r,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
