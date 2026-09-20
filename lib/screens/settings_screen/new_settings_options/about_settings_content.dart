import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/widgets/omisu/omisu_ascii_logo.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:omisu/utils/version_compare.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/data/datasources/sqlite_service.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_title.dart';

class AboutSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;

  const AboutSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  @override
  State<AboutSettingsContent> createState() => AboutSettingsContentState();
}

class AboutSettingsContentState extends State<AboutSettingsContent>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  /// Snaps during rapid D-pad navigation, animates on a single move.
  final AdaptiveScroller _scroller = AdaptiveScroller();

  /// Keys used for calculating viewport alignment during navigation, one per
  /// link card.
  final List<GlobalKey> _itemKeys = List.generate(5, (_) => GlobalKey());

  String _appVersion = '';
  String _systemsVersion = '';
  String _coresVersion = '';
  String _engineVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshVersionLabels();
  }

  /// Reloads app / systems / player version lines (e.g. after GitHub OTA).
  void refreshVersionLabels() {
    _loadAppVersion();
    _loadSystemsVersion();
    _loadBuiltinPlayerVersions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshVersionLabels();
    }
  }

  Future<void> _loadBuiltinPlayerVersions() async {
    if (!Platform.isAndroid) return;
    try {
      final cores = await EmbeddedEmulatorService.getBuiltinCoresVersion();
      final engine =
          await EmbeddedEmulatorService.getBundledLibretroDroidVersion();
      if (mounted) {
        setState(() {
          _coresVersion = cores;
          _engineVersion = engine;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Synchronizes the scroll viewport with the currently focused link card.
  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  Future<void> _loadSystemsVersion() async {
    try {
      final version = await SqliteService.getSystemsVersion();
      if (mounted) {
        setState(() {
          _systemsVersion = version.isNotEmpty ? version : 'bundled';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = formatDisplayAppVersion(
            version: packageInfo.version,
            buildNumber: packageInfo.buildNumber,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'v1.0.0';
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int getItemCount() {
    return 5;
  }

  void selectItem(int index) {
    switch (index) {
      case 0:
        _launchUrl('https://github.com/misobadev/neostation-frontend');
        break;
      case 1:
        _launchUrl('https://ko-fi.com/neostation');
        break;
      case 2:
        _launchUrl('https://www.patreon.com/cw/OmiSU');
        break;
      case 3:
        _launchUrl('https://discord.gg/xE2kgKsRVq');
        break;
      case 4:
        _launchUrl('https://neostation.dev/');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsTitle(title: AppLocale.thankYou.getString(context)),
          SizedBox(height: 12.r),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.r),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 280.r,
                      child: OmisuAsciiLogo(
                        width: 280.r,
                        showBootPrompt: false,
                        color: OmisuAsciiLogo.brandGreen,
                      ),
                    ),
                    SizedBox(height: 6.r),
                    Text(
                      'OmiSU',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.r,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      "Beta $_appVersion",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 9.r,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Systems v$_systemsVersion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 8.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16.r),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBuiltinPlayerPanel(theme),
                      SizedBox(height: 8.h),
                      _buildInfoCard(
                        cardKey: _itemKeys[0],
                        icon: Symbols.code_rounded,
                        title: AppLocale.openSourceLicense.getString(context),
                        value: AppLocale.openSourceLicenseDesc.getString(
                          context,
                        ),
                        url: 'https://github.com/misobadev/neostation-frontend',
                        theme: theme,
                        isFocused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 0,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoCard(
                        cardKey: _itemKeys[1],
                        icon: Symbols.coffee_rounded,
                        title: AppLocale.supportOnKofi.getString(context),
                        value: 'ko-fi.com/neostation',
                        url: 'https://ko-fi.com/neostation',
                        theme: theme,
                        isFocused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 1,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoCard(
                        cardKey: _itemKeys[2],
                        icon: Symbols.favorite_rounded,
                        title: AppLocale.supportOnPatreon.getString(context),
                        value: 'patreon.com/OmiSU',
                        url: 'https://www.patreon.com/cw/OmiSU',
                        theme: theme,
                        isFocused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 2,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoCard(
                        cardKey: _itemKeys[3],
                        icon: Symbols.chat_bubble_outline_rounded,
                        title: AppLocale.joinCommunity.getString(context),
                        value: 'discord.gg/xE2kgKsRVq',
                        url: 'https://discord.gg/xE2kgKsRVq',
                        theme: theme,
                        isFocused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 3,
                      ),
                      SizedBox(height: 8.h),
                      _buildInfoCard(
                        cardKey: _itemKeys[4],
                        icon: Symbols.language_rounded,
                        title: AppLocale.visitWebsite.getString(context),
                        value: 'neostation.dev',
                        url: 'https://neostation.dev/',
                        theme: theme,
                        isFocused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuiltinPlayerPanel(ThemeData theme) {
    final versionLine = Platform.isAndroid && _coresVersion.isNotEmpty
        ? 'Cores v$_coresVersion · LibretroDroid v$_engineVersion'
        : null;

    return OmisuRetroPanel(
      padding: EdgeInsets.all(8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.sports_esports_rounded,
                size: 16.r,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 6.r),
              Text(
                'Built-in player',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.r,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.r),
          Text(
            'In-app emulation uses LibretroDroid and libretro cores from the '
            'LemuroidCores distribution. OmiSU is not the Lemuroid app — these '
            'are open-source components credited in NOTICE.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 9.r,
              height: 1.35,
            ),
          ),
          if (versionLine != null) ...[
            SizedBox(height: 6.r),
            Text(
              versionLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 8.r,
              ),
            ),
          ],
          SizedBox(height: 8.r),
          Wrap(
            spacing: 8.r,
            runSpacing: 4.r,
            children: [
              _linkChip(
                theme,
                'LibretroDroid',
                'https://github.com/Swordfish90/LibretroDroid',
              ),
              _linkChip(
                theme,
                'LemuroidCores',
                'https://github.com/Swordfish90/LemuroidCores',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkChip(ThemeData theme, String label, String url) {
    return InkWell(
      onTap: () {
        SfxService().playNavSound();
        _launchUrl(url);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 8.r,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required GlobalKey cardKey,
    required IconData icon,
    required String title,
    required String value,
    required String url,
    required ThemeData theme,
    bool isFocused = false,
  }) {
    return InkWell(
      key: cardKey,
      onTap: () {
        SfxService().playNavSound();
        _launchUrl(url);
      },
      borderRadius: BorderRadius.circular(12.r),
      canRequestFocus: false,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 8.r),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.r,
                    ),
                  ),
                  SizedBox(height: 2.r),
                  Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 9.r,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.open_in_new_rounded,
              size: 14.r,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
