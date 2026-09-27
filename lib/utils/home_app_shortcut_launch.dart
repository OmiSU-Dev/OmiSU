import 'package:flutter/material.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/my_systems.dart';
import 'package:omisu/services/android_service.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/widgets/custom_notification.dart';
import 'package:flutter_localization/flutter_localization.dart';

/// Launches a home-screen app shortcut (Winlator, GameHub, Steam Link, …).
Future<void> launchHomeAppShortcut(
  BuildContext context,
  SystemInfo systemInfo,
) async {
  final package = systemInfo.appPackageName;
  if (package == null || package.isEmpty) return;

  GamepadNavigationManager.deactivateAll();

  final success = await AndroidService.launchPackage(package);
  if (!context.mounted) return;

  if (!success) {
    GamepadNavigationManager.restoreFocusOwner();
    AppNotification.showNotification(
      context,
      AppLocale.failedToLaunchAndroidApp.getString(context),
      type: NotificationType.error,
    );
  }
}
