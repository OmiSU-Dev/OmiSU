import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/services/nordi/controller_idle_sleep_service.dart';
import 'package:omisu/services/nordi/nordi_sleep_service.dart';

/// Single subscription for [launcher_events] (wake + controller host sleep).
class NordiLauncherEvents {
  NordiLauncherEvents._();

  static const _events = EventChannel('com.omisu.launcher/launcher_events');
  static StreamSubscription<dynamic>? _sub;

  static void ensureListening() {
    if (!Platform.isAndroid || !NordiConfig.curatedBuild) return;
    _sub ??= _events.receiveBroadcastStream().listen((event) {
      if (event is Map && event['event'] == 'controllerHostSleep') {
        ControllerIdleSleepService.handleHostSleepEvent(event);
        return;
      }
      if (event == 'wakeFromSleep') {
        NordiSleepService.handleWakeFromSleepEvent();
      }
    });
  }
}
