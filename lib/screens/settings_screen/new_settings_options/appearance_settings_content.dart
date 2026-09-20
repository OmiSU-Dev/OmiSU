import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/constants/recent_card_sizes.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/ambient_backdrop_mode.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/utils/nav_tabs.dart';
import 'package:provider/provider.dart';

import '../../../providers/sqlite_config_provider.dart';
import '../../../widgets/custom_toggle_switch.dart';
import 'settings_title.dart';
import 'system_art_settings_content.dart';
import 'systems_settings_content.dart';
import 'themes_settings_content.dart';
import 'widgets/setting_row.dart';
import 'widgets/setting_value_chip.dart';

enum _AppearancePanel { main, themes, systemArt, hiddenSystems }

class AppearanceSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;
  final ValueChanged<int>? onSelectionChanged;

  const AppearanceSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
    this.onSelectionChanged,
  });

  @override
  State<AppearanceSettingsContent> createState() =>
      AppearanceSettingsContentState();
}

class AppearanceSettingsContentState extends State<AppearanceSettingsContent> {
  _AppearancePanel _panel = _AppearancePanel.main;

  final ScrollController _scrollController = ScrollController();
  final AdaptiveScroller _scroller = AdaptiveScroller();
  final List<GlobalKey> _itemKeys = [];

  final GlobalKey<ThemesSettingsContentState> _themesKey =
      GlobalKey<ThemesSettingsContentState>();
  final GlobalKey<SystemArtSettingsContentState> _systemArtKey =
      GlobalKey<SystemArtSettingsContentState>();
  final GlobalKey<SystemsSettingsContentState> _hiddenSystemsKey =
      GlobalKey<SystemsSettingsContentState>();

  static const List<String> _gridColumnSizes = ['S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 32; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _inSubPanel => _panel != _AppearancePanel.main;

  int _mainItemCount() {
    // home layout, grid columns, hide recent, recent size, ambient, tabs, 3 links
    return 5 + settingsHidableNavTabs().length + 3;
  }

  int getItemCount() {
    if (_panel == _AppearancePanel.themes) {
      return _themesKey.currentState?.getItemCount(context) ?? 0;
    }
    if (_panel == _AppearancePanel.systemArt) {
      return _systemArtKey.currentState?.getItemCount() ?? 0;
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      final provider = context.read<SqliteConfigProvider>();
      return _hiddenSystemsKey.currentState?.getItemCount(provider) ?? 0;
    }
    return _mainItemCount();
  }

  void _returnToMain() {
    setState(() => _panel = _AppearancePanel.main);
    widget.onSelectionChanged?.call(0);
  }

  void _openSubPanel(_AppearancePanel panel) {
    setState(() => _panel = panel);
    widget.onSelectionChanged?.call(0);
  }

  void navigateUp() {
    if (_panel == _AppearancePanel.themes) {
      _themesKey.currentState?.navigateUp();
      return;
    }
    if (_panel == _AppearancePanel.systemArt) {
      _systemArtKey.currentState?.navigateUp();
      return;
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      final previous = widget.selectedContentIndex;
      final next = (widget.selectedContentIndex - 1).clamp(
        0,
        getItemCount() - 1,
      );
      if (next != previous) widget.onSelectionChanged?.call(next);
      scrollToIndex(next);
      return;
    }

    final previous = widget.selectedContentIndex;
    final next = (widget.selectedContentIndex - 1).clamp(
      0,
      _mainItemCount() - 1,
    );
    if (next != previous) widget.onSelectionChanged?.call(next);
    scrollToIndex(next);
  }

  void navigateDown() {
    if (_panel == _AppearancePanel.themes) {
      _themesKey.currentState?.navigateDown();
      return;
    }
    if (_panel == _AppearancePanel.systemArt) {
      _systemArtKey.currentState?.navigateDown();
      return;
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      final previous = widget.selectedContentIndex;
      final next = (widget.selectedContentIndex + 1).clamp(
        0,
        getItemCount() - 1,
      );
      if (next != previous) widget.onSelectionChanged?.call(next);
      scrollToIndex(next);
      return;
    }

    final previous = widget.selectedContentIndex;
    final next = (widget.selectedContentIndex + 1).clamp(
      0,
      _mainItemCount() - 1,
    );
    if (next != previous) widget.onSelectionChanged?.call(next);
    scrollToIndex(next);
  }

  bool navigateLeft() {
    if (_panel == _AppearancePanel.themes) {
      final returnToMain = _themesKey.currentState?.navigateLeft() ?? true;
      if (returnToMain) _returnToMain();
      return false;
    }
    if (_panel == _AppearancePanel.systemArt) {
      final returnToMain = _systemArtKey.currentState?.navigateLeft() ?? true;
      if (returnToMain) _returnToMain();
      return false;
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      _returnToMain();
      return false;
    }
    return true;
  }

  void navigateRight() {
    if (_panel == _AppearancePanel.themes) {
      _themesKey.currentState?.navigateRight();
      return;
    }
    if (_panel == _AppearancePanel.systemArt) {
      _systemArtKey.currentState?.navigateRight();
    }
  }

  void scrollToIndex(int index) {
    if (_inSubPanel) {
      if (_panel == _AppearancePanel.themes) {
        _themesKey.currentState?.scrollToIndex(index);
      } else if (_panel == _AppearancePanel.systemArt) {
        _systemArtKey.currentState?.scrollToIndex(index);
      } else if (_panel == _AppearancePanel.hiddenSystems) {
        _hiddenSystemsKey.currentState?.scrollToIndex(index);
      }
      return;
    }
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  void deleteFocusedTheme(int index) {
    if (_panel == _AppearancePanel.themes) {
      _themesKey.currentState?.deleteFocusedTheme(index);
    }
  }

  void selectItem(int index) {
    SfxService().playNavSound();
    if (_panel == _AppearancePanel.themes) {
      _themesKey.currentState?.selectItem(index);
      return;
    }
    if (_panel == _AppearancePanel.systemArt) {
      _systemArtKey.currentState?.selectItem(index);
      return;
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      final provider = context.read<SqliteConfigProvider>();
      _hiddenSystemsKey.currentState?.selectItem(index, provider);
      return;
    }

    final provider = context.read<SqliteConfigProvider>();
    var current = 0;

    if (index == current) {
      if (provider.config.systemViewMode != 'grid') {
        provider.updateSystemViewMode('grid');
      }
      return;
    }
    current++;

    if (index == current) {
      final sizes = _gridColumnSizes;
      final idx = sizes.indexOf(provider.config.systemGridColumns);
      final next = sizes[(idx < 0 ? 1 : idx + 1) % sizes.length];
      provider.updateSystemGridColumns(next);
      return;
    }
    current++;

    if (index == current) {
      provider.updateHideRecentCard(!provider.config.hideRecentCard);
      return;
    }
    current++;

    if (index == current) {
      if (!provider.config.hideRecentCard) {
        provider.updateRecentCardSize(
          provider.config.recentCardSize == RecentCardSizes.twoByOne
              ? RecentCardSizes.defaultSize
              : RecentCardSizes.twoByOne,
        );
      }
      return;
    }
    current++;

    if (index == current) {
      provider.updateAmbientBackdropMode(
        provider.config.ambientBackdropMode.next,
      );
      return;
    }
    current++;

    for (final tab in settingsHidableNavTabs()) {
      if (index == current) {
        final hidden =
            navTabSpec(tab).hidden?.call(provider.config) ?? false;
        provider.updateNavTabHidden(tab, !hidden);
        return;
      }
      current++;
    }

    if (index == current) {
      _openSubPanel(_AppearancePanel.themes);
      return;
    }
    current++;

    if (index == current) {
      _openSubPanel(_AppearancePanel.systemArt);
      return;
    }
    current++;

    if (index == current) {
      _openSubPanel(_AppearancePanel.hiddenSystems);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_panel == _AppearancePanel.themes) {
      return ThemesSettingsContent(
        key: _themesKey,
        isContentFocused: widget.isContentFocused,
        selectedContentIndex: widget.selectedContentIndex,
        onSelectionChanged: widget.onSelectionChanged,
      );
    }
    if (_panel == _AppearancePanel.systemArt) {
      return SystemArtSettingsContent(
        key: _systemArtKey,
        isContentFocused: widget.isContentFocused,
        selectedContentIndex: widget.selectedContentIndex,
        onSelectionChanged: widget.onSelectionChanged,
      );
    }
    if (_panel == _AppearancePanel.hiddenSystems) {
      return SystemsSettingsContent(
        key: _hiddenSystemsKey,
        isContentFocused: widget.isContentFocused,
        selectedContentIndex: widget.selectedContentIndex,
        visibilityOnly: true,
      );
    }

    return _buildMainPanel(context);
  }

  Widget _buildMainPanel(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SqliteConfigProvider>();
    final config = provider.config;
    var currentIdx = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.appearance.getString(context),
          subtitle: AppLocale.appearanceSubtitle.getString(context),
        ),
        SizedBox(height: 12.r),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.homeLayout.getString(context),
                    subtitle: AppLocale.homeLayoutSubtitle.getString(context),
                    trailing: SettingValueChip(
                      text: AppLocale.gridView.getString(context),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.cardSizeGroup.getString(context),
                    subtitle: AppLocale.homeLayoutSubtitle.getString(context),
                    trailing: SettingValueChip(
                      text: config.systemGridColumns,
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.hideRecentCard.getString(context),
                    subtitle: AppLocale.hideRecentCardSubtitle.getString(
                      context,
                    ),
                    trailing: CustomToggleSwitch(
                      value: !config.hideRecentCard,
                      onChanged: (value) {
                        provider.updateHideRecentCard(!value);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return Opacity(
                    opacity: config.hideRecentCard ? 0.4 : 1.0,
                    child: SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused: widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.recentCardSize.getString(context),
                      subtitle: AppLocale.recentCardSizeSubtitle.getString(
                        context,
                      ),
                      trailing: SettingValueChip(
                        text: config.recentCardSize == RecentCardSizes.twoByOne
                            ? AppLocale.recentCardSize2x1.getString(context)
                            : AppLocale.recentCardSizeDefault.getString(
                                context,
                              ),
                      ),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  final mode = config.ambientBackdropMode;
                  final label = switch (mode) {
                    AmbientBackdropMode.off =>
                      AppLocale.ambientBackdropOff.getString(context),
                    AmbientBackdropMode.subtle =>
                      AppLocale.ambientBackdropSubtle.getString(context),
                    AmbientBackdropMode.reactive =>
                      AppLocale.ambientBackdropReactive.getString(context),
                    AmbientBackdropMode.screensaver =>
                      AppLocale.ambientBackdropScreensaver.getString(context),
                  };
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.ambientBackdrop.getString(context),
                    subtitle:
                        AppLocale.ambientBackdropSubtitle.getString(context),
                    trailing: SettingValueChip(text: label),
                  );
                }(),
                for (final tab in settingsHidableNavTabs()) ...[
                  SizedBox(height: 12.r),
                  () {
                    final index = currentIdx++;
                    final spec = navTabSpec(tab);
                    final titleKey = spec.settingsTitleKey;
                    final hidden = spec.hidden?.call(config) ?? false;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused: widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: (titleKey ?? spec.labelKey).getString(context),
                      subtitle:
                          spec.settingsSubtitleKey?.getString(context) ?? '',
                      trailing: CustomToggleSwitch(
                        value: !hidden,
                        onChanged: (value) {
                          provider.updateNavTabHidden(tab, !value);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                ],
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.appearanceOpenThemes.getString(context),
                    subtitle: AppLocale.themesSubtitle.getString(context),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: 18.r,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.appearanceOpenSystemArt.getString(
                      context,
                    ),
                    subtitle: AppLocale.systemArtSubtitle.getString(context),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: 18.r,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }(),
                SizedBox(height: 12.r),
                () {
                  final index = currentIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused: widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.appearanceHiddenSystems.getString(context),
                    subtitle: AppLocale.systemsSettingsSubtitle.getString(
                      context,
                    ),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: 18.r,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
