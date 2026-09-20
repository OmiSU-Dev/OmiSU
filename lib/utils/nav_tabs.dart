import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/config_model.dart';
import 'package:omisu/services/nordi/nordi_settings.dart';

/// Identity of a top-level navigation tab (the L1/R1 strip in the header).
///
/// The ordinal **is** the canonical tab index used by `AppScreenState`
/// (`_selectedTabIndex`, `_buildCurrentTabContent`, the secondary-display tab
/// names). Append new tabs at the end — inserting one renumbers every existing
/// tab and silently repoints all of that dispatch.
enum NavTab { systems, search, sync, achievements, scraper, romm, settings, sleep }

/// Static description of one navigation tab: how it is drawn, whether the user
/// may hide it, and how that preference is read and written.
class NavTabSpec {
  const NavTabSpec({
    required this.icon,
    required this.labelKey,
    this.iconData,
    this.accentColor,
    this.hidden,
    this.withHidden,
    this.settingsTitleKey,
    this.settingsSubtitleKey,
  });

  /// Asset drawn in the header strip. Use [iconData] when no asset exists.
  final String icon;

  /// Material symbol fallback for tabs with no webp asset.
  final IconData? iconData;

  /// iiSU-style accent for this tab's active indicator and icon tint.
  final Color? accentColor;

  /// [AppLocale] key for the tab's display name.
  final String labelKey;

  /// Reads this tab's "hidden" preference. `null` means the tab can never be
  /// hidden — that is the default for any tab not wired up here.
  final bool Function(ConfigModel config)? hidden;

  /// Returns a copy of [config] with this tab's "hidden" preference set.
  final ConfigModel Function(ConfigModel config, bool hidden)? withHidden;

  /// [AppLocale] keys for this tab's row in General settings.
  final String? settingsTitleKey;
  final String? settingsSubtitleKey;

  /// Whether the user can toggle this tab's visibility.
  bool get isHidable => hidden != null && withHidden != null;
}

/// Fallback for a [NavTab] with no entry in [navTabSpecs].
///
/// It has no [NavTabSpec.hidden] predicate, so an unregistered tab renders and
/// stays permanently visible rather than disappearing — the safe failure for a
/// tab added in a future version before its toggle is wired up.
const NavTabSpec _fallbackSpec = NavTabSpec(
  icon: 'assets/images/icons/grids.webp',
  labelKey: AppLocale.systems,
);

/// Systems and Settings are deliberately absent a [NavTabSpec.hidden]
/// predicate: Systems is the home tab, and Settings must stay reachable or a
/// user who hid everything else could never turn it back on.
const Map<NavTab, NavTabSpec> navTabSpecs = {
  NavTab.systems: NavTabSpec(
    icon: 'assets/images/icons/grids.webp',
    labelKey: AppLocale.systems,
    accentColor: Color(0xFF00C8FF),
  ),
  NavTab.search: NavTabSpec(
    icon: '',
    labelKey: AppLocale.searchTitle,
    iconData: Symbols.search_rounded,
    accentColor: const Color(0xFF00D390),
    hidden: _hideTabSearch,
    withHidden: _withHideTabSearch,
    settingsTitleKey: AppLocale.showSearchTab,
    settingsSubtitleKey: AppLocale.showSearchTabSubtitle,
  ),
  NavTab.sync: NavTabSpec(
    icon: 'assets/images/icons/cloud-add.webp',
    labelKey: AppLocale.neoSync,
    accentColor: const Color(0xFF5E84FF),
    hidden: _hideTabSync,
    withHidden: _withHideTabSync,
    settingsTitleKey: AppLocale.showSyncTab,
    settingsSubtitleKey: AppLocale.showSyncTabSubtitle,
  ),
  NavTab.achievements: NavTabSpec(
    icon: 'assets/images/icons/enhance-prize.webp',
    labelKey: AppLocale.achievements,
    accentColor: const Color(0xFFFFB020),
    hidden: _hideTabAchievements,
    withHidden: _withHideTabAchievements,
    settingsTitleKey: AppLocale.showAchievementsTab,
    settingsSubtitleKey: AppLocale.showAchievementsTabSubtitle,
  ),
  NavTab.scraper: NavTabSpec(
    icon: 'assets/images/icons/box-search.webp',
    labelKey: AppLocale.scraping,
    accentColor: const Color(0xFFFF627D),
    hidden: _hideTabScraper,
    withHidden: _withHideTabScraper,
    settingsTitleKey: AppLocale.showScraperTab,
    settingsSubtitleKey: AppLocale.showScraperTabSubtitle,
  ),
  NavTab.romm: NavTabSpec(
    icon: 'assets/images/icons/romm-light.svg',
    labelKey: AppLocale.rommLibrary,
    accentColor: Color(0xFF8258FA),
    hidden: _hideTabRomm,
    withHidden: _withHideTabRomm,
    settingsTitleKey: AppLocale.showRommTab,
    settingsSubtitleKey: AppLocale.showRommTabSubtitle,
  ),
  NavTab.settings: NavTabSpec(
    icon: 'assets/images/icons/setting.webp',
    labelKey: AppLocale.settings,
    accentColor: Color(0xFFFF00BF),
  ),
  NavTab.sleep: NavTabSpec(
    icon: '',
    labelKey: AppLocale.nordiSleepTab,
    iconData: Symbols.bedtime_rounded,
    accentColor: Color(0xFF6B7280),
  ),
};

// Torn out as top-level functions so [navTabSpecs] can stay `const`.
bool _hideTabSync(ConfigModel c) => c.hideTabSync;
bool _hideTabAchievements(ConfigModel c) => c.hideTabAchievements;
bool _hideTabScraper(ConfigModel c) => c.hideTabScraper;
bool _hideTabRomm(ConfigModel c) => c.hideTabRomm;
bool _hideTabSearch(ConfigModel c) => c.hideTabSearch;

ConfigModel _withHideTabSync(ConfigModel c, bool hidden) =>
    c.copyWith(hideTabSync: hidden);
ConfigModel _withHideTabAchievements(ConfigModel c, bool hidden) =>
    c.copyWith(hideTabAchievements: hidden);
ConfigModel _withHideTabScraper(ConfigModel c, bool hidden) =>
    c.copyWith(hideTabScraper: hidden);
ConfigModel _withHideTabRomm(ConfigModel c, bool hidden) =>
    c.copyWith(hideTabRomm: hidden);
ConfigModel _withHideTabSearch(ConfigModel c, bool hidden) =>
    c.copyWith(hideTabSearch: hidden);

/// Description of [tab], never null — see [_fallbackSpec].
NavTabSpec navTabSpec(NavTab tab) => navTabSpecs[tab] ?? _fallbackSpec;

/// Tabs the user should see, in canonical order.
///
/// A tab is visible unless it has a registered hide-predicate that says
/// otherwise, so an unregistered (i.e. newly added) tab is visible by default.
List<NavTab> visibleNavTabs(ConfigModel config) => NavTab.values
    .where((tab) => !(navTabSpec(tab).hidden?.call(config) ?? false))
    .toList(growable: false);

/// Tabs the user can toggle, in canonical order. Drives the General settings
/// rows, so wiring a future tab's spec is all it takes to give it a toggle.
List<NavTab> hidableNavTabs() => NavTab.values
    .where((tab) => navTabSpec(tab).isHidable)
    .toList(growable: false);

/// Tabs whose visibility toggles appear in Appearance settings.
///
/// Nordi hides the NeoSync toggle — sync is permanently off on the handheld build.
List<NavTab> settingsHidableNavTabs() {
  if (!NordiSettings.handheldRetailUi) return hidableNavTabs();
  return hidableNavTabs()
      .where((tab) => tab != NavTab.sync)
      .toList(growable: false);
}

/// Fewest tab slots the header strip will show.
///
/// The strip normally shows as many slots as fit beside the status pill, which
/// varies with the screen and with whether the device reports a battery — see
/// `navStripMaxSlots` in `header_layout.dart`. This is the floor for screens
/// too narrow even for that, where the pill scales itself down instead. With
/// more visible tabs than the strip has slots it scrolls; with that many or
/// fewer it renders as a static strip and never scrolls.
const int minNavTabSlots = 5;

/// First slot shown by the scrolling strip after selection moves to
/// [selectedSlot].
///
/// Centered windowing: the selection sits in the window's middle slot (the
/// left-of-middle slot when [maxSlots] is even), clamped at both ends of the
/// strip — so the selection only reaches an edge slot when it is genuinely
/// near the first or last tab, and everywhere else the strip scrolls under a
/// stationary highlight. A [selectedSlot] of -1 (selected tab hidden by a
/// config change) keeps the current [windowStart] rather than snapping
/// anywhere. The result is always clamped so the window never shows blank
/// slots past either end.
int navTabWindowStart({
  required int windowStart,
  required int selectedSlot,
  required int tabCount,
  int maxSlots = minNavTabSlots,
}) {
  if (tabCount <= maxSlots) return 0;
  final start = selectedSlot >= 0
      ? selectedSlot - (maxSlots - 1) ~/ 2
      : windowStart;
  return start.clamp(0, tabCount - maxSlots);
}
