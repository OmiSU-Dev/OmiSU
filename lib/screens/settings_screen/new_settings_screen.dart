import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'new_settings_options/general_settings_content.dart';
import 'new_settings_options/secondary_settings_content.dart';
import 'new_settings_options/library_settings_content.dart';
import 'new_settings_options/tools_settings_content.dart';
import 'new_settings_options/services_settings_content.dart';
import 'new_settings_options/appearance_settings_content.dart';
import 'new_settings_options/input_settings_content.dart';
import 'new_settings_options/playback_settings_content.dart';
import 'new_settings_options/streaming_settings_content.dart';
import 'new_settings_options/about_settings_content.dart';
import 'new_settings_options/exit_settings_content.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:omisu/services/logger_service.dart';
import '../../providers/sqlite_config_provider.dart';
import '../../widgets/omisu/omisu_retro_chrome.dart';
import '../../themes/omisu_accent.dart';
import 'package:omisu/services/nordi/nordi_settings.dart';
import 'new_settings_options/nordi_power_settings_content.dart';

/// A unified Settings dashboard featuring a master-detail layout with category navigation and contextual content panels.
///
/// Implements a static delegation pattern to allow global input managers (e.g., GamepadNavigationManager)
/// to trigger navigation events across the menu and content sub-trees.
class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({super.key});

  /// When set before opening Settings, selects this category on first build.
  static String? pendingCategoryLocaleKey;

  static void requestOpenCategory(String localeKey) {
    pendingCategoryLocaleKey = localeKey;
    _currentInstance?._applyPendingCategory();
  }

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();

  // Static Bridge: Provides delegation targets for external input managers.
  /// Returns whether the selection moved (false when repeating at a list edge),
  /// so callers can gate the nav sound.
  static bool navigateUp() => _currentInstance?._navigateUp() ?? true;
  static bool navigateDown() => _currentInstance?._navigateDown() ?? true;
  static void navigateLeft() => _currentInstance?._navigateLeft();
  static void navigateRight() => _currentInstance?._navigateRight();
  static void selectCurrent() => _currentInstance?._selectItem();
  static void backCurrent() => _currentInstance?._navigateBack();
  static void deleteCurrent() => _currentInstance?._deleteCurrentItem();

  static _NewSettingsScreenState? _currentInstance;
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  int _selectedMenuIndex = 0;
  int _selectedContentIndex = 0;

  /// Focus State: [true] indicates navigation within the category menu; [false] indicates content interaction.
  bool _focusOnMenu = true;

  static final _log = LoggerService.instance;

  final List<SettingsMenuItem> _menuItems = [];

  /// Key attached to the currently-selected left-menu item, so it can be
  /// scrolled into view (e.g. the bottom "Exit" entry on small displays).
  final GlobalKey _selectedMenuItemKey = GlobalKey();

  /// Snaps during rapid D-pad navigation, animates on a single move.
  final AdaptiveScroller _menuScroller = AdaptiveScroller();

  /// Brings the selected category menu item into view after the next frame.
  void _scrollMenuToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedMenuItemKey.currentContext;
      if (ctx == null) return;
      _menuScroller.ensureVisible(ctx);
    });
  }

  // Content Keys: Used for cross-component communication and scrolling orchestration.
  final GlobalKey<GeneralSettingsContentState> _generalSettingsKey =
      GlobalKey<GeneralSettingsContentState>();
  final GlobalKey<LibrarySettingsContentState> _librarySettingsKey =
      GlobalKey<LibrarySettingsContentState>();
  final GlobalKey<ServicesSettingsContentState> _servicesSettingsKey =
      GlobalKey<ServicesSettingsContentState>();
  final GlobalKey<AppearanceSettingsContentState> _appearanceSettingsKey =
      GlobalKey<AppearanceSettingsContentState>();
  final GlobalKey<InputSettingsContentState> _inputSettingsKey =
      GlobalKey<InputSettingsContentState>();
  final GlobalKey<SecondarySettingsContentState> _secondarySettingsKey =
      GlobalKey<SecondarySettingsContentState>();
  final GlobalKey<ToolsSettingsContentState> _toolsSettingsKey =
      GlobalKey<ToolsSettingsContentState>();
  final GlobalKey<PlaybackSettingsContentState> _playbackSettingsKey =
      GlobalKey<PlaybackSettingsContentState>();
  final GlobalKey<StreamingSettingsContentState> _streamingSettingsKey =
      GlobalKey<StreamingSettingsContentState>();
  final GlobalKey<AboutSettingsContentState> _aboutSettingsKey =
      GlobalKey<AboutSettingsContentState>();
  final GlobalKey<ExitSettingsContentState> _exitSettingsKey =
      GlobalKey<ExitSettingsContentState>();
  final GlobalKey<NordiPowerSettingsContentState> _nordiPowerKey =
      GlobalKey<NordiPowerSettingsContentState>();

  @override
  void initState() {
    super.initState();
    NewSettingsScreen._currentInstance = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeMenuItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyPendingCategory();
    });
  }

  void _applyPendingCategory() {
    final key = NewSettingsScreen.pendingCategoryLocaleKey;
    if (key == null) return;
    NewSettingsScreen.pendingCategoryLocaleKey = null;
    final idx = _menuItems.indexWhere((item) => item.localeKey == key);
    if (idx < 0) return;
    _onMenuItemSelected(idx);
  }

  @override
  void dispose() {
    NewSettingsScreen._currentInstance = null;
    super.dispose();
  }

  /// Tracks whether the menu currently includes the Secondary Display category,
  /// so [build] can rebuild the menu when the secondary connection changes.
  bool _menuIncludesSecondary = false;

  /// Populates the configuration categories for the side menu. The Secondary
  /// Display category is included only while a secondary display is active.
  void _initializeMenuItems() {
    _menuItems.clear();
    void addItem(SettingsMenuItem item) {
      if (NordiSettings.isMenuHidden(item.localeKey)) return;
      _menuItems.add(item);
    }
    _menuIncludesSecondary = context
        .read<SqliteConfigProvider>()
        .isSecondaryActive;

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.general,
        icon: Symbols.settings_rounded,
        isVisible: true,
      ),
    );

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.library,
        icon: Symbols.folder_rounded,
        isVisible: true,
      ),
    );

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.services,
        icon: Symbols.cloud_sync_rounded,
        isVisible: true,
      ),
    );

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.appearance,
        icon: Symbols.palette_rounded,
        isVisible: true,
      ),
    );

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.input,
        icon: Symbols.sports_esports_rounded,
        isVisible: true,
      ),
    );

    if (_menuIncludesSecondary) {
      addItem(
        SettingsMenuItem(
          title: '',
          localeKey: AppLocale.secondaryDisplay,
          icon: Symbols.cast_rounded,
          isVisible: true,
        ),
      );
    }

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.tools,
        icon: Symbols.build_rounded,
        isVisible: true,
      ),
    );

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.playback,
        icon: Symbols.play_circle_rounded,
        isVisible: true,
      ),
    );

    if (Platform.isAndroid) {
      addItem(
        SettingsMenuItem(
          title: '',
          localeKey: AppLocale.streaming,
          icon: Symbols.live_tv_rounded,
          isVisible: true,
        ),
      );
    }

    addItem(
      SettingsMenuItem(
        title: '',
        localeKey: AppLocale.about,
        icon: Symbols.info_rounded,
        isVisible: true,
      ),
    );

    if (!NordiSettings.isMenuHidden(AppLocale.exit)) {
      addItem(
        SettingsMenuItem(
          title: '',
          localeKey: AppLocale.exit,
          icon: Symbols.exit_to_app_rounded,
          isVisible: true,
        ),
      );
    }
    if (NordiSettings.handheldRetailUi) {
      _menuItems.add(
        SettingsMenuItem(
          title: 'Restart / Reboot',
          localeKey: NordiSettings.powerMenuLocaleKey,
          icon: Symbols.restart_alt_rounded,
          isVisible: true,
        ),
      );
    }
  }

  /// Switches the active settings category and resets the content-level focus.
  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedMenuIndex = index;
      _focusOnMenu = true;
      _selectedContentIndex = 0;
    });

    // Auto-focus content for immediate termination confirmation if Exit is selected.
    if (_menuItems[index].localeKey == AppLocale.exit) {
      _focusOnMenu = false;
      _selectedContentIndex = 0;
    }

    if (_menuItems[index].localeKey == AppLocale.about) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _aboutSettingsKey.currentState?.refreshVersionLabels();
      });
    }
  }

  /// Vertical Navigation Protocol: Handles wrap-around menu scrolling and content list progression.
  ///
  /// Returns whether the selection actually moved, so the caller can suppress
  /// the nav sound when repeating against the start/end of a list.
  bool _navigateUp() {
    if (_focusOnMenu) {
      setState(() {
        _selectedMenuIndex =
            (_selectedMenuIndex - 1 + _menuItems.length) % _menuItems.length;
      });
      _scrollMenuToSelected();
      return true;
    }

    // Content-Specific Navigation Overrides.
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.navigateUp();
      return true;
    }

    // Generic linear navigation within content lists.
    final previousIndex = _selectedContentIndex;
    setState(() {
      _selectedContentIndex = (_selectedContentIndex - 1).clamp(
        0,
        _getContentItemCount() - 1,
      );
    });
    _triggerContentScroll();
    return _selectedContentIndex != previousIndex;
  }

  /// Orchestrates visual alignment in content views to maintain visibility of the focused item.
  void _triggerContentScroll() {
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.general) {
      _generalSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.library) {
      _librarySettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.services) {
      _servicesSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.input) {
      _inputSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.secondaryDisplay) {
      _secondarySettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.tools) {
      _toolsSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.playback) {
      _playbackSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.streaming) {
      _streamingSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    } else if (selectedKey == AppLocale.about) {
      _aboutSettingsKey.currentState?.scrollToIndex(_selectedContentIndex);
    }
  }

  bool _navigateDown() {
    if (_focusOnMenu) {
      setState(() {
        _selectedMenuIndex = (_selectedMenuIndex + 1) % _menuItems.length;
      });
      _scrollMenuToSelected();
      return true;
    }

    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.navigateDown();
      return true;
    }

    final previousIndex = _selectedContentIndex;
    setState(() {
      _selectedContentIndex = (_selectedContentIndex + 1).clamp(
        0,
        _getContentItemCount() - 1,
      );
    });
    _triggerContentScroll();
    return _selectedContentIndex != previousIndex;
  }

  /// Hands focus back to the category menu and resets the content cursor.
  ///
  /// The panel is scrolled back to its first item as well: the cursor moves to
  /// index 0, so leaving the viewport parked wherever the user had scrolled to
  /// would show a selection that is off-screen until focus re-enters.
  void _returnFocusToMenu() {
    setState(() {
      _focusOnMenu = true;
      _selectedContentIndex = 0;
    });
    _triggerContentScroll();
  }

  /// Leftward Navigation Protocol: Returns focus to the master menu from the detail panel.
  void _navigateLeft() {
    if (_focusOnMenu) return;

    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.appearance) {
      final returnToMenu =
          _appearanceSettingsKey.currentState?.navigateLeft() ?? true;
      if (returnToMenu) _returnFocusToMenu();
    } else {
      _returnFocusToMenu();
    }
  }

  /// Rightward Navigation Protocol: Moves focus into the detail panel from the master menu.
  void _navigateRight() {
    if (_focusOnMenu && _getContentItemCount() > 0) {
      setState(() {
        _focusOnMenu = false;
        _selectedContentIndex = 0;
      });
      _triggerContentScroll();
      return;
    }

    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.navigateRight();
    }
  }

  /// Execution Protocol: Triggers the action associated with the current focus point.
  ///
  /// On the category menu, A enters the detail panel, matching the A-to-open /
  /// B-to-back convention used by the game list. D-pad Right still does the
  /// same thing, so the existing muscle memory keeps working.
  void _selectItem() {
    if (_focusOnMenu) {
      _onMenuItemSelected(_selectedMenuIndex);
      // Exit auto-focuses its own content, so only step right when the
      // selection actually stayed on the menu.
      if (_focusOnMenu) _navigateRight();
    } else {
      _selectContentItem();
    }
  }

  /// Back Protocol: B always returns focus to the category menu in one press.
  ///
  /// It deliberately does not reuse [_navigateLeft]: in the grid-based
  /// categories (Themes, System Art) Left is a cell move, so delegating there
  /// would make B walk the row instead of backing out. On the menu itself B is
  /// a no-op, as elsewhere at the root of a tab.
  void _navigateBack() {
    if (_focusOnMenu) return;
    _returnFocusToMenu();
  }

  /// Delete Protocol: routes the X button to a delete action on the focused
  /// content item. Currently only the Themes category (imported themes) uses it.
  void _deleteCurrentItem() {
    if (_focusOnMenu) return;
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.deleteFocusedTheme(
        _selectedContentIndex,
      );
    }
  }

  /// Resolves the total item count for the currently active category.
  int _getContentItemCount() {
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.general) {
      return _generalSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.library) {
      return _librarySettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.services) {
      return _servicesSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.appearance) {
      return _appearanceSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.input) {
      return _inputSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.secondaryDisplay) {
      return _secondarySettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.tools) {
      return _toolsSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.playback) {
      return _playbackSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.streaming) {
      return _streamingSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == AppLocale.about) {
      return _aboutSettingsKey.currentState?.getItemCount() ?? 0;
    } else if (selectedKey == NordiSettings.powerMenuLocaleKey) {
      return _nordiPowerKey.currentState?.getItemCount() ?? 3;
    } else if (selectedKey == AppLocale.exit) {
      return 1;
    } else {
      return 0;
    }
  }

  /// Dispatches selection events to the specialized content controllers.
  void _selectContentItem() {
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;
    if (selectedKey == AppLocale.general) {
      _generalSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.library) {
      _librarySettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.services) {
      _servicesSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.appearance) {
      _appearanceSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.input) {
      _inputSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.tools) {
      _toolsSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.playback) {
      _playbackSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.streaming) {
      _streamingSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.secondaryDisplay) {
      _secondarySettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.about) {
      _aboutSettingsKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == NordiSettings.powerMenuLocaleKey) {
      _nordiPowerKey.currentState?.selectItem(_selectedContentIndex);
    } else if (selectedKey == AppLocale.exit) {
      _executeExit();
    }
  }

  /// Multi-tier Termination Protocol: Handles platform-specific exits and OS-level shutdown requests.
  void _executeExit() {
    final config = context.read<SqliteConfigProvider>().config;
    final bool shouldShutdown = config.bartopExitPoweroff;

    if (Platform.isAndroid) {
      // The secondary display's persisted artwork is neutralised by
      // SqliteConfigProvider.didChangeAppLifecycleState on the detached that
      // follows this pop, so no explicit clear is needed here.
      SystemNavigator.pop();
    } else {
      if (shouldShutdown) {
        try {
          if (Platform.isWindows) {
            Process.runSync('shutdown', ['/s', '/t', '0']);
          } else if (Platform.isLinux) {
            Process.runSync('shutdown', ['-h', 'now']);
          }
        } catch (e) {
          _log.e('OS-level shutdown attempt failed: $e');
        }
      }
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Rebuild the side menu when the secondary connection changes so the
    // Secondary Display category appears/disappears with it. Clamp the menu
    // cursor in case the list shrank under it.
    final secondaryActive = context
        .watch<SqliteConfigProvider>()
        .isSecondaryActive;
    if (secondaryActive != _menuIncludesSecondary) {
      _initializeMenuItems();
      _selectedMenuIndex = _selectedMenuIndex.clamp(0, _menuItems.length - 1);
    }

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: 46.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Navigation Master List (25% Width).
          _buildLeftMenu(theme),

          // Right Detail Panel (75% Width).
          _buildRightContent(theme),
        ],
      ),
    );
  }

  Widget _buildLeftMenu(ThemeData theme) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 8.r),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: OmisuAccent.focusGradient[0].withValues(alpha: 0.18),
            width: 1.r,
          ),
        ),
      ),
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          if (!item.isVisible) return const SizedBox.shrink();

          final isSelected = _selectedMenuIndex == index;
          final focused = isSelected && _focusOnMenu;

          return Padding(
            key: isSelected ? _selectedMenuItemKey : null,
            padding: EdgeInsets.only(bottom: 4.r),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  SfxService().playNavSound();
                  _onMenuItemSelected(index);
                },
                borderRadius: BorderRadius.circular(4.r),
                canRequestFocus: false,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: OmisuRetroPanel(
                  active: focused,
                  cornerRadius: 4,
                  padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 10.r),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: focused
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        size: 18.r,
                      ),
                      SizedBox(width: 10.r),
                      Expanded(
                        child: Text(
                          item.localeKey.getString(context),
                          style: omisuRetroLabelStyle(
                            context,
                            size: 11,
                            weight: focused ? FontWeight.w700 : FontWeight.w600,
                            color: focused
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContent(ThemeData theme) {
    return Expanded(
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(16.r),
        child: _buildContentForSelectedMenu(theme),
      ),
    );
  }

  /// Resolution Engine: Instantiates the appropriate detail content based on the master menu selection.
  Widget _buildContentForSelectedMenu(ThemeData theme) {
    final selectedKey = _menuItems[_selectedMenuIndex].localeKey;

    if (selectedKey == AppLocale.general) {
      return GeneralSettingsContent(
        key: _generalSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
        onFullscreenToggle: (value) {},
        onHandheldPolicyChanged: () {
          setState(() {
            _initializeMenuItems();
            _selectedMenuIndex = _selectedMenuIndex.clamp(0, _menuItems.length - 1);
          });
        },
      );
    } else if (selectedKey == AppLocale.library) {
      return LibrarySettingsContent(
        key: _librarySettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.services) {
      return ServicesSettingsContent(
        key: _servicesSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.appearance) {
      return AppearanceSettingsContent(
        key: _appearanceSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
        onSelectionChanged: (newIndex) {
          setState(() {
            _selectedContentIndex = newIndex;
          });
        },
      );
    } else if (selectedKey == AppLocale.input) {
      return InputSettingsContent(
        key: _inputSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.secondaryDisplay) {
      return SecondarySettingsContent(
        key: _secondarySettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.tools) {
      return ToolsSettingsContent(
        key: _toolsSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.playback) {
      return PlaybackSettingsContent(
        key: _playbackSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.streaming) {
      return StreamingSettingsContent(
        key: _streamingSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.about) {
      return AboutSettingsContent(
        key: _aboutSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == NordiSettings.powerMenuLocaleKey) {
      return NordiPowerSettingsContent(
        key: _nordiPowerKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
      );
    } else if (selectedKey == AppLocale.exit) {
      return ExitSettingsContent(
        key: _exitSettingsKey,
        isContentFocused: !_focusOnMenu,
        selectedContentIndex: _selectedContentIndex,
        onExitPressed: _executeExit,
        onCancel: _returnFocusToMenu,
      );
    } else {
      return Center(
        child: Text(
          'Category: ${_menuItems[_selectedMenuIndex].title}',
          style: theme.textTheme.titleLarge,
        ),
      );
    }
  }
}

/// Metadata model for configuration categories.
class SettingsMenuItem {
  final String title;
  final String localeKey;
  final IconData icon;
  final bool isVisible;

  SettingsMenuItem({
    required this.title,
    required this.localeKey,
    required this.icon,
    this.isVisible = true,
  });
}
