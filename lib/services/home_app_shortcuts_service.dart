import 'dart:io';

import 'package:omisu/constants/home_app_shortcut_packages.dart';
import 'package:omisu/models/my_systems.dart';
import 'package:omisu/services/android_service.dart';

/// Builds optional home-grid cards that launch PC-gaming wrapper apps (Winlator, etc.).
class HomeAppShortcutsService {
  HomeAppShortcutsService._();

  static List<SystemInfo>? _cache;

  static void invalidateCache() => _cache = null;

  static Future<List<SystemInfo>> loadShortcutCards() async {
    if (!Platform.isAndroid) return const [];
    if (_cache != null) return _cache!;

    final installed = await AndroidService.getInstalledApps();
    final labelByPackage = <String, String>{};
    for (final app in installed) {
      final pkg = app['package']?.toString() ?? app['packageName']?.toString();
      if (pkg == null || pkg.isEmpty) continue;
      final label = app['name']?.toString() ?? app['label']?.toString();
      if (label != null && label.isNotEmpty) {
        labelByPackage[pkg] = label;
      }
    }

    final cards = <SystemInfo>[];
    for (final entry in HomeAppShortcutPackages.candidates) {
      if (cards.length >= HomeAppShortcutPackages.maxHomeCards) break;
      if (!labelByPackage.containsKey(entry.packageName)) continue;
      final title = labelByPackage[entry.packageName] ?? entry.fallbackLabel;
      cards.add(SystemInfo.fromHomeAppShortcut(
        packageName: entry.packageName,
        title: title,
      ));
    }

    _cache = cards;
    return cards;
  }
}
