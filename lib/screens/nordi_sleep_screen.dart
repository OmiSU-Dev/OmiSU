import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/screens/app_screen.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/services/nordi/nordi_sleep_service.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/gamepad_nav.dart';

/// Nordi sleep tab — confirm with A, then dims the panel and turns the display off.
class NordiSleepScreen extends StatefulWidget {
  const NordiSleepScreen({super.key});

  @override
  State<NordiSleepScreen> createState() => _NordiSleepScreenState();
}

class _NordiSleepScreenState extends State<NordiSleepScreen>
    with WidgetsBindingObserver {
  late final GamepadNavigation _gamepadNav;
  GamepadNavigation? _sleepWakeNav;
  bool _sleeping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NordiSleepService.onWakeFromDeviceSleep = _onNativeWake;
    _gamepadNav = GamepadNavigation(
      onSelectItem: _onConfirmSleep,
      onBack: () {
        SfxService().playBackSound();
        AppNavigation.goToTab(AppTabs.systems);
      },
      onPreviousTab: AppNavigation.previousTab,
      onNextTab: AppNavigation.nextTab,
      onLeftBumper: AppNavigation.previousTab,
      onRightBumper: AppNavigation.nextTab,
      allowRepeat: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadNav.initialize();
      GamepadNavigationManager.pushLayer(
        'nordi_sleep',
        onActivate: () => _gamepadNav.activate(),
        onDeactivate: () => _gamepadNav.deactivate(),
      );
    });
  }

  @override
  void dispose() {
    if (NordiSleepService.onWakeFromDeviceSleep == _onNativeWake) {
      NordiSleepService.onWakeFromDeviceSleep = null;
    }
    _popSleepWakeNav();
    GamepadNavigationManager.popLayer('nordi_sleep');
    _gamepadNav.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onNativeWake() {
    if (!mounted || !_sleeping) return;
    setState(() => _sleeping = false);
    _popSleepWakeNav();
    AppNavigation.goToTab(AppTabs.systems);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _sleeping) {
      unawaited(_wakeAndLeave());
    }
  }

  void _onConfirmSleep() {
    if (_sleeping) return;
    SfxService().playEnterSound();
    unawaited(_enterSleep());
  }

  Future<void> _enterSleep() async {
    if (_sleeping) return;
    setState(() => _sleeping = true);
    _gamepadNav.deactivate();
    _pushSleepWakeNav();
    await NordiSleepService.enterSleep();
  }

  void _pushSleepWakeNav() {
    _sleepWakeNav ??= GamepadNavigation(
      onSettings: _wakeAndLeave,
      allowRepeat: false,
    );
    final nav = _sleepWakeNav!;
    nav.initialize();
    GamepadNavigationManager.pushLayer(
      'nordi_sleep_wake',
      onActivate: () => nav.activate(),
      onDeactivate: () => nav.deactivate(),
    );
    nav.activate();
  }

  void _popSleepWakeNav() {
    if (_sleepWakeNav == null) return;
    GamepadNavigationManager.popLayer('nordi_sleep_wake');
    _sleepWakeNav!.dispose();
    _sleepWakeNav = null;
  }

  Future<void> _wakeAndLeave() async {
    if (!_sleeping) return;
    await NordiSleepService.wake();
    if (!mounted) return;
    setState(() => _sleeping = false);
    _popSleepWakeNav();
    AppNavigation.goToTab(AppTabs.systems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_sleeping) {
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => unawaited(_wakeAndLeave()),
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.r),
              child: Text(
                AppLocale.nordiSleepWake.getString(context),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  fontSize: 10.r,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.bedtime_rounded,
              size: 48.r,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.r),
            Text(
              AppLocale.nordiSleepTab.getString(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.r,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.r),
            Text(
              AppLocale.nordiSleepHint.getString(context),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 11.r,
              ),
            ),
            SizedBox(height: 16.r),
            Text(
              AppLocale.nordiSleepConfirm.getString(context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
                fontSize: 10.r,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
