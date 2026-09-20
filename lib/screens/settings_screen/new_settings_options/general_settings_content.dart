import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import '../../../providers/sqlite_config_provider.dart';
import '../../../widgets/custom_toggle_switch.dart';
import 'settings_title.dart';
import 'widgets/setting_row.dart';
import 'widgets/setting_value_chip.dart';
import 'widgets/language_picker_overlay.dart';
import '../../../services/permission_service.dart';
import '../../../services/sfx_service.dart';
import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/services/nordi/nordi_safe_mode_service.dart';
import 'package:omisu/services/unified_update_coordinator.dart';

/// A specialized content panel for system-wide configuration, including platform-specific orchestration (Windows/Android/Linux).
///
/// Manages high-level preferences such as background scanning, SFX feedback,
/// localization, and native hardware features (Fullscreen, Launcher mode, Multi-display).
class GeneralSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;
  final Function(bool) onFullscreenToggle;
  final VoidCallback? onHandheldPolicyChanged;

  const GeneralSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
    required this.onFullscreenToggle,
    this.onHandheldPolicyChanged,
  });

  @override
  State<GeneralSettingsContent> createState() => GeneralSettingsContentState();
}

class GeneralSettingsContentState extends State<GeneralSettingsContent>
    with WidgetsBindingObserver {
  bool _isDefaultLauncher = false;
  bool _manualUpdateInFlight = false;

  static final _log = LoggerService.instance;

  final ScrollController _scrollController = ScrollController();

  /// Keys for scroll-into-view orchestration during gamepad navigation.
  final List<GlobalKey> _itemKeys = [];

  /// Snaps during rapid D-pad navigation, animates on a single move.
  final AdaptiveScroller _scroller = AdaptiveScroller();

  /// The UI sound volume stops the SFX volume row cycles through, quietest
  /// first. The last entry is the level the app has always played at.
  static const List<double> _sfxVolumeCycle = [
    SfxService.maxVolume / 3,
    SfxService.maxVolume * 2 / 3,
    SfxService.maxVolume,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFullscreenState();
    _checkDefaultLauncher();

    // Pre-allocate keys for maximum theoretical setting items (the fixed rows
    // plus one per navigation tab that can be toggled).
    for (int i = 0; i < 16; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  bool get _retailHandheld =>
      NordiConfig.curatedBuild && !NordiSafeModeService.isEnabled;

  bool get _showLauncherPicker =>
      !NordiConfig.curatedBuild || NordiSafeModeService.isEnabled;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Platform: Android - Refresh critical permission and launcher states upon resume.
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _checkDefaultLauncher();
        context.read<SqliteConfigProvider>().refreshAllFilesAccess();
      });
    }
  }

  /// Sychronizes the native window state with persistent preferences.
  Future<void> _loadFullscreenState() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final isFullscreen = context.read<SqliteConfigProvider>().isFullscreen;
        if (Platform.isMacOS) {
          await windowManager.setFullScreen(isFullscreen);
        } else {
          FullScreenWindow.setFullScreen(isFullscreen);
        }
      } catch (e) {
        _log.e('Failed to synchronize native fullscreen state: $e');
      }
    }
  }

  /// Toggles the native window display mode (Desktop Platforms).
  Future<void> _toggleFullscreen(bool value) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await context.read<SqliteConfigProvider>().updateIsFullscreen(value);
        if (Platform.isMacOS) {
          await windowManager.setFullScreen(value);
        } else {
          FullScreenWindow.setFullScreen(value);
        }
        widget.onFullscreenToggle(value);
      } catch (e) {
        _log.e('Fullscreen state transition failed: $e');
      }
    }
  }

  /// Platform: Android - Verifies if the application is registered as the system-default launcher.
  Future<void> _checkDefaultLauncher() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.omisu.launcher/launcher');
        final isDefault =
            await platform.invokeMethod<bool>('isDefaultLauncher') ?? false;
        setState(() {
          _isDefaultLauncher = isDefault;
        });
      } catch (e) {
        _log.e('Launcher status check failed: $e');
        setState(() {
          _isDefaultLauncher = false;
        });
      }
    }
  }

  /// Platform: Android - Orchestrates the 'All Files Access' permission flow.
  Future<void> _handlePermissionToggle(SqliteConfigProvider provider) async {
    if (provider.hasAllFilesAccess) {
      // If access is already granted, navigate the user to system settings for manual revocation.
      await PermissionService.openAllFilesAccessSettings();
    } else {
      // Initiation of the platform-specific permission request flow.
      final success = await PermissionService.requestAllFilesAccess();
      if (success) {
        provider.refreshAllFilesAccess();
      }
    }
  }

  Future<void> _toggleSafeMode() async {
    final next = !NordiSafeModeService.isEnabled;
    await NordiSafeModeService.setEnabled(next);
    if (!mounted) return;
    setState(() {});
    widget.onHandheldPolicyChanged?.call();
  }

  /// Platform: Android - Triggers the system-default launcher selection activity.
  Future<void> _toggleLauncher(bool value) async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.omisu.launcher/launcher');
        await platform.invokeMethod('openLauncherSettings');
      } catch (e) {
        _log.e('Launcher settings activity could not be resolved: $e');
      }
    }
  }

  /// Platform: Android - Triggers the native system settings activity.
  Future<void> _runManualUpdateCheck() async {
    if (_manualUpdateInFlight || !Platform.isAndroid) return;
    _manualUpdateInFlight = true;
    setState(() {});
    try {
      await UnifiedUpdateCoordinator.runManualCheck(
        context: context,
        configProvider: context.read<SqliteConfigProvider>(),
      );
    } finally {
      if (mounted) {
        _manualUpdateInFlight = false;
        setState(() {});
      }
    }
  }

  Future<void> _openSystemSettings() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.omisu.launcher/launcher');
        final method = _retailHandheld
            ? 'openAndroidSystemUpdates'
            : 'openSystemSettings';
        await platform.invokeMethod(method);
      } catch (e) {
        _log.e('System settings activity could not be resolved: $e');
      }
    }
  }

  /// Dynamic Item Resolution: Calculates the total setting items available for the current platform/configuration.
  int getItemCount() {
    int count = 0;
    if (Platform.isAndroid) {
      count++; // System updates / settings
    }
    if (Platform.isAndroid && NordiConfig.curatedBuild) {
      count++; // Nordi safe mode
    }
    if (Platform.isAndroid && NordiConfig.curatedBuild) {
      count++; // Auto-update App
      count++; // Auto-update Systems
      count++; // Manual update check
    }
    count++; // SFX Sounds
    count++; // SFX volume
    count++; // 12-Hour Clock
    count++; // Language
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      count++; // Fullscreen
    }
    if (Platform.isAndroid) {
      if (!NordiConfig.curatedBuild) {
        count++; // All Files Access
      }
      if (_showLauncherPicker) {
        count++; // Launcher
      }
      count++; // Secondary Display Suppression
    }
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      count++; // BarTOP Power Management
    }
    return count;
  }

  void selectItem(int index) {
    SfxService().playNavSound();
    int currentItemIndex = 0;
    final configProvider = context.read<SqliteConfigProvider>();

    // Protocol: Native Android Settings.
    if (Platform.isAndroid) {
      if (index == currentItemIndex) {
        _openSystemSettings();
        return;
      }
      currentItemIndex++;
    }

    if (Platform.isAndroid && NordiConfig.curatedBuild) {
      if (index == currentItemIndex) {
        _toggleSafeMode();
        return;
      }
      currentItemIndex++;
    }

    if (Platform.isAndroid && NordiConfig.curatedBuild) {
      if (index == currentItemIndex) {
        configProvider.updateAutoUpdateSystems(
          !configProvider.config.autoUpdateSystems,
        );
        return;
      }
      currentItemIndex++;

      if (index == currentItemIndex) {
        unawaited(_runManualUpdateCheck());
        return;
      }
      currentItemIndex++;
    }

    // Protocol: Interface Sound Effects.
    if (index == currentItemIndex) {
      final sfxEnabled = configProvider.config.sfxEnabled;
      configProvider.updateSfxEnabled(!sfxEnabled);
      return;
    }
    currentItemIndex++;

    // Protocol: Interface Sound Effects Volume. The row stays navigable while
    // SFX are off so the setting is still discoverable, but selecting it then
    // does nothing — there is no level to hear.
    if (index == currentItemIndex) {
      if (configProvider.config.sfxEnabled) {
        _cycleSfxVolume(configProvider);
      }
      return;
    }
    currentItemIndex++;

    // Protocol: 12-Hour Clock Format.
    if (index == currentItemIndex) {
      configProvider.updateUse12HourClock(
        !configProvider.config.use12HourClock,
      );
      return;
    }
    currentItemIndex++;

    // Protocol: Localization Selection.
    if (index == currentItemIndex) {
      _showLanguagePicker(context, _itemKeys[currentItemIndex]);
      return;
    }
    currentItemIndex++;

    // Protocol: Native Windowing (Desktop).
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (index == currentItemIndex) {
        final isFullscreen = configProvider.isFullscreen;
        _toggleFullscreen(!isFullscreen);
        return;
      }
      currentItemIndex++;
    }

    // Protocol: Android Permissions & Launcher Lifecycle.
    if (Platform.isAndroid) {
      if (!NordiConfig.curatedBuild) {
        if (index == currentItemIndex) {
          _handlePermissionToggle(configProvider);
          return;
        }
        currentItemIndex++;
      }

      if (_showLauncherPicker) {
        if (index == currentItemIndex) {
          _toggleLauncher(!_isDefaultLauncher);
          return;
        }
        currentItemIndex++;
      }

      if (index == currentItemIndex) {
        final hideBottomScreen = configProvider.config.hideBottomScreen;
        configProvider.updateHideBottomScreen(
          !hideBottomScreen,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.toARGB32(),
        );
        return;
      }
      currentItemIndex++;
    }

    // Protocol: BarTOP Power Management (System Shutdown).
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      if (index == currentItemIndex) {
        final bartopExitPoweroff = configProvider.config.bartopExitPoweroff;
        configProvider.updateBartopExitPoweroff(!bartopExitPoweroff);
        return;
      }
      currentItemIndex++;
    }
  }

  /// Advances the UI sound volume to the next stop and persists it, wrapping
  /// round at the loudest. If the stored value isn't on a stop — a database
  /// written by an older build, or one hand-edited — snaps to the nearest one
  /// first so the first press is never a silent no-op.
  void _cycleSfxVolume(SqliteConfigProvider provider) {
    final current = provider.config.sfxVolume;
    final index = _sfxVolumeCycle.indexWhere(
      (stop) => (stop - current).abs() < 0.001,
    );
    final next = index < 0
        ? _sfxVolumeCycle.reduce(
            (a, b) => (a - current).abs() <= (b - current).abs() ? a : b,
          )
        : _sfxVolumeCycle[(index + 1) % _sfxVolumeCycle.length];
    provider.updateSfxVolume(next);
  }

  /// The localized label for a UI sound volume stop.
  String _sfxVolumeLabel(BuildContext context, double volume) {
    final index = _sfxVolumeCycle.indexWhere(
      (stop) => (stop - volume).abs() < 0.001,
    );
    return switch (index) {
      0 => AppLocale.sfxVolumeLow.getString(context),
      1 => AppLocale.sfxVolumeMedium.getString(context),
      _ => AppLocale.sfxVolumeHigh.getString(context),
    };
  }

  /// Synchronizes the scroll viewport with the currently focused setting item.
  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SqliteConfigProvider>();
    final config = provider.config;
    int currentItemIdx = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned header — stays put while the settings list scrolls beneath it.
        SettingsTitle(title: AppLocale.generalSettings.getString(context)),
        SizedBox(height: 12.r),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Setting: System Settings (Android only).
                if (Platform.isAndroid) ...[
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: _retailHandheld
                          ? 'Android system updates'
                          : AppLocale.androidSystemSettings.getString(context),
                      subtitle: _retailHandheld
                          ? 'Open the ROM system update screen'
                          : AppLocale.androidSystemSettingsSubtitle
                              .getString(context),
                      trailing: Icon(
                        Symbols.open_in_new_rounded,
                        size: 18.r,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    );
                  }(),
                  SizedBox(height: 12.r),
                ],

                if (Platform.isAndroid && NordiConfig.curatedBuild) ...[
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: 'Safe mode (dev / sideload)',
                      subtitle:
                          'Shows Exit and default launcher picker; disables crash relaunch. '
                          'Restart the app after changing.',
                      trailing: CustomToggleSwitch(
                        value: NordiSafeModeService.isEnabled,
                        onChanged: (value) async {
                          await NordiSafeModeService.setEnabled(value);
                          if (!context.mounted) return;
                          setState(() {});
                          widget.onHandheldPolicyChanged?.call();
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                  SizedBox(height: 12.r),
                ],

                if (Platform.isAndroid && NordiConfig.curatedBuild) ...[
                  SizedBox(height: 12.r),
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.nordiAutoUpdatePlayer.getString(context),
                      subtitle: AppLocale.nordiAutoUpdatePlayerSubtitle
                          .getString(context),
                      trailing: CustomToggleSwitch(
                        value: config.autoUpdateSystems,
                        onChanged: (value) {
                          context
                              .read<SqliteConfigProvider>()
                              .updateAutoUpdateSystems(value);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                  SizedBox(height: 12.r),
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: _manualUpdateInFlight
                          ? null
                          : () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.checkForUpdatesNow.getString(context),
                      subtitle: AppLocale.checkForUpdatesNowSubtitle.getString(
                        context,
                      ),
                      trailing: _manualUpdateInFlight
                          ? SizedBox(
                              width: 22.r,
                              height: 22.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.r,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Symbols.sync_rounded,
                              size: 20.r,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                    );
                  }(),
                ],

                // Setting: SFX Feedback.
                SizedBox(height: 12.r),
                () {
                  final index = currentItemIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused:
                        widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.sfxSounds.getString(context),
                    subtitle: AppLocale.sfxSoundsSubtitle.getString(context),
                    trailing: CustomToggleSwitch(
                      value: config.sfxEnabled,
                      onChanged: (value) {
                        context.read<SqliteConfigProvider>().updateSfxEnabled(
                          value,
                        );
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  );
                }(),

                // Setting: SFX Volume. Only meaningful when SFX are on, so it
                // greys out and ignores input while they are off — the same
                // treatment Secondary Screen gives its dependent value rows.
                SizedBox(height: 12.r),
                () {
                  final index = currentItemIdx++;
                  return Opacity(
                    opacity: config.sfxEnabled ? 1.0 : 0.4,
                    child: SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.sfxVolume.getString(context),
                      subtitle: AppLocale.sfxVolumeSubtitle.getString(context),
                      trailing: SettingValueChip(
                        text: _sfxVolumeLabel(context, config.sfxVolume),
                      ),
                    ),
                  );
                }(),

                // Setting: 12-Hour Clock Format.
                SizedBox(height: 12.r),
                () {
                  final index = currentItemIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused:
                        widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.use12HourClock.getString(context),
                    subtitle: AppLocale.use12HourClockSubtitle.getString(
                      context,
                    ),
                    trailing: CustomToggleSwitch(
                      value: config.use12HourClock,
                      onChanged: (value) {
                        context
                            .read<SqliteConfigProvider>()
                            .updateUse12HourClock(value);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  );
                }(),

                // Setting: Localization & Language.
                SizedBox(height: 12.r),
                () {
                  final index = currentItemIdx++;
                  return SettingRow(
                    key: _itemKeys[index],
                    onTap: () => selectItem(index),
                    focused:
                        widget.isContentFocused &&
                        widget.selectedContentIndex == index,
                    title: AppLocale.language.getString(context),
                    subtitle: AppLocale.languageSub.getString(context),
                    trailing: SettingValueChip(
                      text:
                          AppLocale.supportedLanguages[config.appLanguage] ??
                          config.appLanguage,
                      trailingIcon: Symbols.arrow_drop_down_rounded,
                    ),
                  );
                }(),

                // Setting: Native Fullscreen (Desktop Platforms).
                if (!kIsWeb &&
                    (Platform.isWindows ||
                        Platform.isLinux ||
                        Platform.isMacOS)) ...[
                  SizedBox(height: 12.r),
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      expandTitle: false,
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.fullscreenMode.getString(context),
                      subtitle: AppLocale.fullscreenModeSubtitle.getString(
                        context,
                      ),
                      trailing: CustomToggleSwitch(
                        value: provider.isFullscreen,
                        onChanged: _toggleFullscreen,
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                ],

                // Setting: Filesystem Access & Launcher (Android).
                if (Platform.isAndroid) ...[
                  if (!NordiConfig.curatedBuild) ...[
                    SizedBox(height: 12.r),
                    () {
                      final index = currentItemIdx++;
                      return SettingRow(
                        key: _itemKeys[index],
                        onTap: () => selectItem(index),
                        focused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == index,
                        title: AppLocale.allFilesAccess.getString(context),
                        subtitle: '',
                        subtitleWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.hasAllFilesAccess
                                  ? AppLocale.permissionGranted.getString(
                                      context,
                                    )
                                  : AppLocale.permissionDisabled.getString(
                                      context,
                                    ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 9.r,
                                fontWeight: FontWeight.bold,
                                color: provider.hasAllFilesAccess
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            SizedBox(height: 2.r),
                            Text(
                              AppLocale.allFilesAccessSubtitle.getString(
                                context,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 8.r,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: CustomToggleSwitch(
                          value: provider.hasAllFilesAccess,
                          onChanged: (value) =>
                              _handlePermissionToggle(provider),
                          activeColor: theme.colorScheme.primary,
                        ),
                      );
                    }(),
                  ],
                  if (_showLauncherPicker) ...[
                    SizedBox(height: 12.r),
                    () {
                      final index = currentItemIdx++;
                      return SettingRow(
                        key: _itemKeys[index],
                        onTap: () => selectItem(index),
                        focused:
                            widget.isContentFocused &&
                            widget.selectedContentIndex == index,
                        title: AppLocale.defaultLauncher.getString(context),
                        subtitle: _isDefaultLauncher
                            ? AppLocale.isDefaultLauncher.getString(context)
                            : AppLocale.setAsDefaultLauncher.getString(
                                context,
                              ),
                        trailing: CustomToggleSwitch(
                          value: _isDefaultLauncher,
                          onChanged: _toggleLauncher,
                          activeColor: theme.colorScheme.primary,
                        ),
                      );
                    }(),
                  ],
                ],

                // Setting: Secondary Display Suppression (Android Multi-Display).
                if (Platform.isAndroid) ...[
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.disableSecondaryScreen.getString(
                        context,
                      ),
                      subtitle: AppLocale.disableSecondaryScreenSub.getString(
                        context,
                      ),
                      trailing: CustomToggleSwitch(
                        value: config.hideBottomScreen,
                        onChanged: (value) {
                          provider.updateHideBottomScreen(
                            value,
                            backgroundColor: theme.scaffoldBackgroundColor
                                .toARGB32(),
                          );
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                ],

                // Setting: BarTOP Shutdown (Windows/Linux Power Management).
                if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) ...[
                  SizedBox(height: 12.r),
                  () {
                    final index = currentItemIdx++;
                    return SettingRow(
                      key: _itemKeys[index],
                      onTap: () => selectItem(index),
                      focused:
                          widget.isContentFocused &&
                          widget.selectedContentIndex == index,
                      title: AppLocale.bartopShutdown.getString(context),
                      subtitle: AppLocale.bartopShutdownSubtitle.getString(
                        context,
                      ),
                      trailing: CustomToggleSwitch(
                        value: config.bartopExitPoweroff,
                        onChanged: (value) {
                          context
                              .read<SqliteConfigProvider>()
                              .updateBartopExitPoweroff(value);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  }(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Displays an autonomous overlay for selecting the application language.
  void _showLanguagePicker(BuildContext ctx, GlobalKey rowKey) async {
    final RenderBox? box =
        rowKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset offset = box?.localToGlobal(Offset.zero) ?? const Offset(0, 0);
    final Size size = box?.size ?? Size.zero;

    final configProvider = ctx.read<SqliteConfigProvider>();
    final currentLang = configProvider.config.appLanguage;

    final result = await showGeneralDialog<String>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Language Picker',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, _) {
        return FadeTransition(
          opacity: animation,
          child: LanguagePickerOverlay(
            anchorOffset: offset + Offset(size.width, size.height / 2),
            currentLang: currentLang,
          ),
        );
      },
    );

    if (result != null && mounted) {
      context.read<SqliteConfigProvider>().updateAppLanguage(result);
    }
  }
}
