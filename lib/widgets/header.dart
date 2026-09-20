import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:omisu/providers/theme_provider.dart';
import 'package:omisu/responsive.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/services/permission_service.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:omisu/providers/omisu_shell_provider.dart';
import 'package:omisu/widgets/omisu/omisu_status_title_pill.dart';
import 'package:omisu/widgets/omisu/omisu_brand_mark.dart';
import 'package:omisu/widgets/omisu/omisu_shell_layout.dart';
import 'package:omisu/widgets/omisu/omisu_status_hud.dart';
import 'package:omisu/utils/header_layout.dart';
import 'package:omisu/widgets/bumper_glyph.dart';
import 'package:omisu/utils/time_format.dart';

/// Top status bar + optional focus title — tab strip lives in [OmisuNavDock].
class Header extends StatefulWidget {
  final int selectedTabIndex;
  final Function(int) onTabSelected;

  const Header({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  bool _isTelevision = false;
  DateTime _now = DateTime.now();
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _getBatteryLevel();
    _listenToBatteryState();
    _updateTime();
    _startTimeUpdateTimer();
    if (Platform.isAndroid) {
      PermissionService.isTelevision().then((isTV) {
        if (mounted && isTV) setState(() => _isTelevision = true);
      });
    }
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  void _listenToBatteryState() {
    try {
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() => _batteryState = state);
        }
      });
    } catch (_) {}
  }

  void _updateTime() {
    if (mounted) {
      setState(() => _now = DateTime.now());
      _getBatteryLevel();
    }
  }

  void _startTimeUpdateTimer() {
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;

    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      if (mounted) {
        _updateTime();
        _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          if (mounted) {
            _updateTime();
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          if (Platform.isLinux && level == 0) {
            _batteryLevel = -1;
          } else {
            _batteryLevel = level;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _batteryLevel = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SqliteConfigProvider>(
      builder: (context, themeProvider, configProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final clockText = formatClockTime(
              _now,
              use12Hour: configProvider.config.use12HourClock,
            );
            final showBattery =
                _batteryLevel != -1 &&
                !_isTelevision &&
                !Responsive.isHandheldXS(context);
            final labelStyle = omisuRetroLabelStyle(context, size: 11);
            final shoulderStyle = configProvider.config.gamepadShoulderStyle;

            final pillAllowance = statusPillMaxWidth(
              totalWidth: constraints.maxWidth,
              navStripWidth: 0,
              margin: 8.r,
              gutter: 4.r,
            );

            // Option 3: no clock glyph — width budget without it.
            final naturalWidth = statusPillWidth(
              clockTextWidth: _measureText(context, clockText, labelStyle),
              batteryTextWidth: showBattery
                  ? _measureText(context, '$_batteryLevel%', labelStyle)
                  : 0,
              withClockGlyph: false,
              horizontalPadding: 10.r,
              bell: 14.r,
              bellGap: 10.r,
              batteryGap: 12.r,
              batteryIcon: 16.r,
              batteryIconGap: 4.r,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: kOmisuTopBarHeight.r,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.r),
                    child: Row(
                      children: [
                        BumperGlyph(
                          isLeft: true,
                          size: 22.r,
                          style: shoulderStyle,
                        ),
                        SizedBox(width: 8.r),
                        const OmisuBrandMark(compact: true),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: pillAllowance > 0
                                ? pillAllowance
                                : naturalWidth,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: OmisuStatusHud(
                              clockText: clockText,
                              batteryLevel: _batteryLevel,
                              batteryState: _batteryState,
                              showBattery: showBattery,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.r),
                        BumperGlyph(
                          isLeft: false,
                          size: 22.r,
                          style: shoulderStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                Consumer<OmisuShellProvider>(
                  builder: (context, shell, _) {
                    if (!shell.homeChromeActive ||
                        shell.focusTitle == null ||
                        shell.focusTitle!.isEmpty) {
                      return SizedBox(height: 2.r);
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.r),
                      child: OmisuStatusTitlePill(
                        title: shell.focusTitle!,
                        subtitle: shell.focusSubtitle,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _measureText(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }
}
