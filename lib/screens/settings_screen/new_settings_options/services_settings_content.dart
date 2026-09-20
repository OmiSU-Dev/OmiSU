import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/repositories/retro_achievements_repository.dart';
import 'package:omisu/repositories/scraper_repository.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/utils/nav_tabs.dart';
import 'package:omisu/widgets/info_dialog.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:provider/provider.dart';

import 'package:omisu/config/nordi_config.dart';
import '../../../providers/romm_provider.dart';
import '../../../providers/sqlite_config_provider.dart';
import '../../../screens/app_screen.dart';
import '../../../widgets/custom_toggle_switch.dart';
import '../../romm_screen/romm_connect_content.dart';
import 'settings_title.dart';
import 'widgets/setting_row.dart';

/// Online services panel — RomM, ScreenScraper, NeoSync, and RetroAchievements.
class ServicesSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;

  const ServicesSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  @override
  State<ServicesSettingsContent> createState() =>
      ServicesSettingsContentState();
}

class ServicesSettingsContentState extends State<ServicesSettingsContent> {
  final ScrollController _scrollController = ScrollController();
  final AdaptiveScroller _scroller = AdaptiveScroller();
  final List<GlobalKey> _itemKeys = List.generate(5, (_) => GlobalKey());

  String? _scraperUsername;
  bool _scraperLoaded = false;
  bool _rommPanelExpanded = false;

  static const int _raBacklogWarnThreshold = 500;

  @override
  void initState() {
    super.initState();
    _loadScraperCredentials();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScraperCredentials() async {
    try {
      final creds = await ScraperRepository.getSavedCredentials();
      if (!mounted) return;
      setState(() {
        _scraperUsername = creds?['username'];
        _scraperLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _scraperLoaded = true);
    }
  }

  bool get _hideNeoSync => NordiConfig.curatedBuild;

  int getItemCount() => _hideNeoSync ? 4 : 5;

  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  Future<void> _setRaMatchOnStartup(bool value) async {
    final configProvider = context.read<SqliteConfigProvider>();
    if (!value) {
      configProvider.updateRaMatchOnStartup(false);
      return;
    }

    final coverage = await RetroAchievementsRepository.getRaHashCoverage();
    final backlog = coverage.eligible - coverage.hashed;
    if (!mounted) return;
    configProvider.updateRaMatchOnStartup(true);

    if (backlog < _raBacklogWarnThreshold) return;
    await InfoDialog.show(
      context,
      title: AppLocale.raMatchOnStartup.getString(context),
      body: AppLocale.raMatchOnStartupBacklogWarning
          .getString(context)
          .replaceFirst('{count}', backlog.toString()),
      okLabel: AppLocale.ok.getString(context),
      icon: Symbols.trophy_rounded,
    );
  }

  void selectItem(int index) {
    SfxService().playNavSound();
    final provider = context.read<SqliteConfigProvider>();

    switch (index) {
      case 0:
        provider.updateAutoScrapeNewGames(!provider.config.autoScrapeNewGames);
      case 1:
        provider.updateAutoScrapeWifiOnly(!provider.config.autoScrapeWifiOnly);
      case 2:
        AppNavigation.goToTab(NavTab.scraper.index);
      case 3:
        _setRaMatchOnStartup(!provider.config.raMatchOnStartup);
      case 4:
        if (!_hideNeoSync) {
          AppNavigation.goToTab(NavTab.sync.index);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.watch<SqliteConfigProvider>().config;
    final rommConnected = context.watch<RommProvider>().isConnected;
    var row = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.services.getString(context),
          subtitle: AppLocale.servicesSubtitle.getString(context),
        ),
        SizedBox(height: 12.r),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingRow(
                  key: _itemKeys[row],
                  onTap: () => selectItem(row),
                  focused: widget.isContentFocused &&
                      widget.selectedContentIndex == row,
                  title: AppLocale.autoScrapeNewGames.getString(context),
                  subtitle: AppLocale.autoScrapeNewGamesSubtitle.getString(
                    context,
                  ),
                  trailing: CustomToggleSwitch(
                    value: config.autoScrapeNewGames,
                    onChanged: (value) {
                      context
                          .read<SqliteConfigProvider>()
                          .updateAutoScrapeNewGames(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 12.r),
                () {
                  row++;
                  return Opacity(
                    opacity: Platform.isAndroid ? 1.0 : 0.45,
                    child: SettingRow(
                      key: _itemKeys[row],
                      onTap: Platform.isAndroid ? () => selectItem(row) : null,
                      focused: widget.isContentFocused &&
                          widget.selectedContentIndex == row,
                      title: AppLocale.autoScrapeWifiOnly.getString(context),
                      subtitle: AppLocale.autoScrapeWifiOnlySubtitle.getString(
                        context,
                      ),
                      trailing: CustomToggleSwitch(
                        value: config.autoScrapeWifiOnly,
                        onChanged: Platform.isAndroid
                            ? (value) {
                                context
                                    .read<SqliteConfigProvider>()
                                    .updateAutoScrapeWifiOnly(value);
                              }
                            : null,
                        activeColor: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  row++;
                  final connected = _scraperUsername?.isNotEmpty == true;
                  return SettingRow(
                    key: _itemKeys[row],
                    onTap: () => selectItem(row),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == row,
                    title: AppLocale.screenscraper.getString(context),
                    subtitle: !_scraperLoaded
                        ? AppLocale.loading.getString(context)
                        : connected
                        ? _scraperUsername!
                        : AppLocale.loginToScrape.getString(context),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: 18.r,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  row++;
                  return SettingRow(
                    key: _itemKeys[row],
                    onTap: () => selectItem(row),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == row,
                    title: AppLocale.raMatchOnStartup.getString(context),
                    subtitle: AppLocale.raMatchOnStartupSubtitle.getString(
                      context,
                    ),
                    trailing: CustomToggleSwitch(
                      value: config.raMatchOnStartup,
                      onChanged: _setRaMatchOnStartup,
                      activeColor: theme.colorScheme.primary,
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                if (!_hideNeoSync) ...[
                () {
                  row++;
                  return SettingRow(
                    key: _itemKeys[row],
                    onTap: () => selectItem(row),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == row,
                    title: AppLocale.neoSync.getString(context),
                    subtitle: AppLocale.neoSyncDescription.getString(context),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: 18.r,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                ],
                OmisuRetroPanel(
                  padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Symbols.cloud_sync_rounded,
                        size: 16.r,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8.r),
                      Expanded(
                        child: Text(
                          AppLocale.servicesEmbeddedPlayNote.getString(context),
                          style: omisuRetroLabelStyle(
                            context,
                            size: 9,
                            weight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.r),
                SettingRow(
                  onTap: () {
                    SfxService().playNavSound();
                    setState(() => _rommPanelExpanded = !_rommPanelExpanded);
                  },
                  focused: false,
                  title: AppLocale.rommLogin.getString(context),
                  subtitle: AppLocale.rommInfoSelfHosted.getString(context),
                  trailing: Icon(
                    _rommPanelExpanded || rommConnected
                        ? Symbols.expand_less_rounded
                        : Symbols.expand_more_rounded,
                    size: 18.r,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (_rommPanelExpanded || rommConnected) ...[
                  SizedBox(height: 12.r),
                  RommConnectContent(embeddedInSettings: true),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
