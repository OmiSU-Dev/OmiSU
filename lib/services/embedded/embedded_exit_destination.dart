import 'package:flutter/material.dart';
import 'package:omisu/screens/systems_screen/my_systems_section/my_systems_grid.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/utils/nav_tabs.dart';
import 'package:omisu/utils/root_navigator_key.dart';
import 'package:omisu/screens/app_screen.dart';

/// Tracks the in-game exit request and applies post-launch navigation.
class EmbeddedExitHandler {
  EmbeddedExitHandler._();

  static bool _pendingHomeExit = false;
  static int _homeNavigationGeneration = 0;
  static final List<VoidCallback> _homeRevealListeners = [];

  /// Lets systems UI (carousel, games list) remount before the game route pops.
  static void registerHomeRevealListener(VoidCallback listener) {
    if (!_homeRevealListeners.contains(listener)) {
      _homeRevealListeners.add(listener);
    }
  }

  static void unregisterHomeRevealListener(VoidCallback listener) {
    _homeRevealListeners.remove(listener);
  }

  /// Show home shell under the embedded route (avoids black gap after [Navigator.pop]).
  static void revealHomeUnderEmbeddedExit() {
    MySystems.gridLaunchNotifier.value = false;
    for (final listener in List<VoidCallback>.from(_homeRevealListeners)) {
      listener();
    }
  }

  static void markPendingHome() {
    _pendingHomeExit = true;
  }

  static bool consumePendingHome() {
    final pending = _pendingHomeExit;
    _pendingHomeExit = false;
    return pending;
  }

  /// Pops pushed routes and switches to the Systems tab.
  static void navigateToHome() {
    final generation = ++_homeNavigationGeneration;
    revealHomeUnderEmbeddedExit();
    AppNavigation.goToTab(NavTab.systems.index);
    GamepadNavigationManager.clearLaunchFocusOwner();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _homeNavigationGeneration) {
        return;
      }
      final navigator = rootNavigatorKey.currentState;
      final canPop = navigator?.canPop() ?? false;
      if (navigator != null && canPop) {
        navigator.popUntil((route) => route.isFirst);
      }
      GamepadNavigationManager.popLayer('embedded_game');
      GamepadNavigationManager.popLayersAbove('my_systems_list');
      AppNavigation.activate();
    });
  }
}
