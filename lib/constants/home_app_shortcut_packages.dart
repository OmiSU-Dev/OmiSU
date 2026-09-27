/// Launcher apps for PC / Steam-style play on Android, shown as home grid shortcuts
/// when installed (Phase 1 — no per-user picker yet).
class HomeAppShortcutPackages {
  HomeAppShortcutPackages._();

  /// Ordered by preference; at most [maxHomeCards] installed entries are shown.
  static const int maxHomeCards = 4;

  static const List<HomeAppShortcutEntry> candidates = [
    HomeAppShortcutEntry('com.winlator.cmod', 'Winlator'),
    HomeAppShortcutEntry('com.cmodded.winlator', 'Winlator Proot'),
    HomeAppShortcutEntry('com.winlator', 'Winlator'),
    HomeAppShortcutEntry('com.winlator.vanilla', 'Winlator'),
    HomeAppShortcutEntry('gamehub.lite', 'GameHub Lite'),
    HomeAppShortcutEntry('banner.hub.lite', 'Banner Hub Lite'),
    HomeAppShortcutEntry('banner.hub', 'Banner Hub'),
    HomeAppShortcutEntry('com.xiaoji.egggame', 'GameHub'),
    HomeAppShortcutEntry('com.micewine.emu', 'MiceWine'),
    HomeAppShortcutEntry('com.valvesoftware.steamlink', 'Steam Link'),
  ];
}

class HomeAppShortcutEntry {
  const HomeAppShortcutEntry(this.packageName, this.fallbackLabel);

  final String packageName;
  final String fallbackLabel;
}
