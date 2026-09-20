import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/models/core_emulator_model.dart';
import 'package:omisu/models/embedded_core_config.dart';
import 'package:omisu/models/game_model.dart';
import 'package:omisu/models/system_model.dart';
import 'package:omisu/repositories/game_repository.dart';
import 'package:omisu/screens/app_screen.dart';
import 'package:omisu/screens/settings_screen/new_settings_screen.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/services/streaming/stream_settings_service.dart';
import 'package:omisu/widgets/custom_toggle_switch.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:omisu/utils/emulator_loader.dart';
import 'package:omisu/widgets/settings_rows.dart';

/// Per-game emulator override tab for [GameSettingsDialog].
///
/// Lists 'System Default' plus every emulator available for the game's
/// system, mirroring the behavior of the list view's settings tab.
class GameSettingsEmulatorTab extends StatefulWidget {
  final GameModel game;
  final SystemModel system;
  final bool isAllMode;
  final VoidCallback? onGameUpdated;

  const GameSettingsEmulatorTab({
    super.key,
    required this.game,
    required this.system,
    required this.isAllMode,
    this.onGameUpdated,
  });

  @override
  State<GameSettingsEmulatorTab> createState() =>
      GameSettingsEmulatorTabState();
}

class GameSettingsEmulatorTabState extends State<GameSettingsEmulatorTab> {
  static final _log = LoggerService.instance;

  List<CoreEmulatorModel> _availableEmulators = [];
  int _selectedIndex = 0;
  bool _streamOnLaunch = false;
  StreamSettings _streamSettings = const StreamSettings();

  /// Tracks the active emulator override. Uses a sentinel to differentiate
  /// between 'not yet loaded' and 'explicit null' (system default).
  Object? _activeEmulatorId = _sentinel;
  static const Object _sentinel = Object();

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  GlobalKey _itemKey(int navIndex) =>
      _itemKeys.putIfAbsent(navIndex, () => GlobalKey());

  String get _streamPrefsKey =>
      widget.game.romPath ?? widget.game.romname;

  String? get _resolvedEmulatorId => identical(_activeEmulatorId, _sentinel)
      ? widget.game.emulatorName
      : _activeEmulatorId as String?;

  bool get _usesAndroidBuiltinTab =>
      Platform.isAndroid &&
      EmbeddedCoreRegistry.supports(widget.system.folderName);

  int get _totalItems {
    if (_usesAndroidBuiltinTab) {
      return 2;
    }
    return _availableEmulators.isEmpty ? 0 : 1 + _availableEmulators.length;
  }

  @override
  void initState() {
    super.initState();
    _loadEmulators();
    unawaited(_loadStreamingPrefs());
  }

  Future<void> _loadStreamingPrefs() async {
    await StreamSettingsService.ensureStreamCredentials();
    final onLaunch = await StreamSettingsService.getStreamOnLaunch(
      _streamPrefsKey,
    );
    if (!mounted) return;
    setState(() {
      _streamSettings = StreamSettingsService.current;
      _streamOnLaunch = onLaunch;
    });
  }

  Future<void> _setStreamOnLaunch(bool enabled) async {
    setState(() => _streamOnLaunch = enabled);
    await StreamSettingsService.setStreamOnLaunch(_streamPrefsKey, enabled);
  }

  void _openStreamingSettings() {
    Navigator.of(context).pop();
    NewSettingsScreen.requestOpenCategory(AppLocale.streaming);
    AppNavigation.goToTab(AppTabs.settings);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEmulators() async {
    final emulators = await loadEmulatorsForSystem(widget.system);
    if (mounted) setState(() => _availableEmulators = emulators);
  }

  void scrollFocusedItemIntoView() => _scrollToSelectedItem();

  bool moveUp() {
    if (_totalItems == 0) return false;
    final next = (_selectedIndex - 1).clamp(0, _totalItems - 1);
    if (next == _selectedIndex) return false;
    setState(() => _selectedIndex = next);
    _scrollToSelectedItem();
    return true;
  }

  bool moveDown() {
    if (_totalItems == 0) return false;
    final next = (_selectedIndex + 1).clamp(0, _totalItems - 1);
    if (next == _selectedIndex) return false;
    setState(() => _selectedIndex = next);
    _scrollToSelectedItem();
    return true;
  }

  void trigger() {
    if (_totalItems == 0) return;
    if (_usesAndroidBuiltinTab) {
      if (_selectedIndex == 0) {
        if (_streamSettings.isConfigured) {
          _setStreamOnLaunch(!_streamOnLaunch);
        }
      }
      return;
    }
    if (_selectedIndex == 0) {
      _setEmulatorOverride(null);
      return;
    }
    final emulator = _availableEmulators[_selectedIndex - 1];
    if (!emulator.isInstalled) return;
    _setEmulatorOverride(emulator);
  }

  void _scrollToSelectedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[_selectedIndex];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  /// Persists a manual emulator override for this specific game.
  Future<void> _setEmulatorOverride(CoreEmulatorModel? emulator) async {
    // Optimistic update: reflect changes in UI immediately.
    if (mounted) setState(() => _activeEmulatorId = emulator?.uniqueId);
    try {
      final targetSystemFolder =
          widget.isAllMode && widget.game.systemFolderName != null
          ? widget.game.systemFolderName!
          : widget.system.folderName;
      await GameRepository.setEmulatorOverride(
        targetSystemFolder,
        widget.game.romname,
        emulator?.uniqueId,
        emulator?.osId,
      );
      widget.onGameUpdated?.call();
    } catch (e) {
      _log.e('Emulator override persistence failed: $e');
      // Rollback: revert UI state on failure.
      if (mounted) {
        setState(() => _activeEmulatorId = widget.game.emulatorName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_availableEmulators.isEmpty &&
        !EmbeddedCoreRegistry.supports(widget.system.folderName)) {
      return Center(
        child: Text(
          AppLocale.noEmulator.getString(context),
          style: TextStyle(
            fontSize: 12.r,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Android: built-in LibretroDroid is the out-of-box default for supported
    // systems — not the RetroArch entries from the legacy systems database.
    if (Platform.isAndroid &&
        EmbeddedCoreRegistry.supports(widget.system.folderName)) {
      return _buildAndroidBuiltinTab(context);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!Platform.isAndroid &&
              EmbeddedCoreRegistry.supports(widget.system.folderName))
            _buildLinuxPreviewBanner(context),
          if (!Platform.isAndroid &&
              EmbeddedCoreRegistry.supports(widget.system.folderName))
            Padding(
              padding: EdgeInsets.only(left: 4.r, bottom: 8.r, top: 4.r),
              child: Text(
                AppLocale.linuxPreviewEmulators.getString(context),
                style: TextStyle(
                  fontSize: 10.r,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ..._buildEmulatorRows(context),
        ],
      ),
    );
  }

  Widget _buildStreamingToggle(BuildContext context, {bool selected = false}) {
    final theme = Theme.of(context);
    return OmisuRetroPanel(
      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(selected ? 4.r : 0),
          child: _buildStreamingToggleBody(context),
        ),
      ),
    );
  }

  Widget _buildStreamingToggleBody(BuildContext context) {
    final configured = _streamSettings.isConfigured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.live_tv_rounded,
              size: 14.r,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 6.r),
            Expanded(
              child: Text(
                AppLocale.streamingStreamOnLaunch.getString(context),
                style: TextStyle(fontSize: 11.r, fontWeight: FontWeight.w600),
              ),
            ),
            CustomToggleSwitch(
              value: _streamOnLaunch,
              disabled: !configured,
              onChanged: configured ? _setStreamOnLaunch : null,
            ),
          ],
        ),
        SizedBox(height: 4.r),
        Text(
          configured
              ? AppLocale.streamingStreamOnLaunchSubtitle.getString(context)
              : AppLocale.streamingSetupRequired.getString(context),
          style: TextStyle(
            fontSize: 10.r,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        if (!configured) ...[
          SizedBox(height: 6.r),
          TextButton(
            onPressed: _openStreamingSettings,
            child: Text(AppLocale.streamingOpenSettings.getString(context)),
          ),
        ],
      ],
    );
  }

  Widget _buildAndroidBuiltinTab(BuildContext context) {
    final config = EmbeddedCoreRegistry.configFor(widget.system.folderName);
    final coreLabel = config?.coreName ?? 'libretro';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: _itemKey(0),
            child: _buildStreamingToggle(
              context,
              selected: _selectedIndex == 0,
            ),
          ),
          SizedBox(height: 10.r),
          Padding(
            padding: EdgeInsets.only(left: 4.r, bottom: 4.r),
            child: Row(
              children: [
                Icon(
                  Symbols.sports_esports_rounded,
                  size: 12.r,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: 4.r),
                Text(
                  AppLocale.emulator.getString(context),
                  style: TextStyle(
                    fontSize: 11.r,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _BuiltinPlayerRow(
            key: _itemKey(1),
            isSelected: _selectedIndex == 1,
            label: AppLocale.builtinPlayerLabel.getString(context),
            coreName: coreLabel,
            onTap: () {
              SfxService().playNavSound();
              setState(() => _selectedIndex = 1);
              _setEmulatorOverride(null);
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4.r, 8.r, 4.r, 0),
            child: Text(
              AppLocale.playbackEmbeddedNote.getString(context),
              style: TextStyle(
                fontSize: 10.r,
                height: 1.35,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinuxPreviewBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.r),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Symbols.info_rounded,
            size: 14.r,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 8.r),
          Expanded(
            child: Text(
              AppLocale.embeddedPlayDesktopDetails.getString(context),
              style: TextStyle(
                fontSize: 10.r,
                height: 1.35,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEmulatorRows(BuildContext context) {
    return [
      Padding(
        padding: EdgeInsets.only(left: 4.r, bottom: 4.r),
        child: Row(
          children: [
            Icon(
              Symbols.sports_esports_rounded,
              size: 12.r,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 4.r),
            Text(
              AppLocale.emulator.getString(context),
              style: TextStyle(
                fontSize: 11.r,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      // Global System Default Option.
      EmulatorRow(
        key: _itemKey(0),
        isSelected: _selectedIndex == 0,
        label: AppLocale.systemDefault.getString(context),
        isActive:
            _resolvedEmulatorId == null ||
            !_availableEmulators.any(
              (e) => e.uniqueId == _resolvedEmulatorId,
            ),
        onTap: () {
          SfxService().playNavSound();
          setState(() => _selectedIndex = 0);
          _setEmulatorOverride(null);
        },
      ),
      // Individual Emulator Options.
      ..._availableEmulators.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        return EmulatorRow(
          key: _itemKey(i + 1),
          isSelected: _selectedIndex == i + 1,
          label: e.name,
          isActive: _resolvedEmulatorId == e.uniqueId,
          onTap: () {
            SfxService().playNavSound();
            setState(() => _selectedIndex = i + 1);
            _setEmulatorOverride(e);
          },
          emulator: e,
        );
      }),
    ];
  }
}

class _BuiltinPlayerRow extends StatelessWidget {
  final bool isSelected;
  final String label;
  final String coreName;
  final VoidCallback onTap;

  const _BuiltinPlayerRow({
    super.key,
    required this.isSelected,
    required this.label,
    required this.coreName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 4.r),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 6.r),
          child: Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Icon(
                  Symbols.videogame_asset_rounded,
                  size: 12.r,
                  color: theme.colorScheme.secondary,
                ),
              ),
              SizedBox(width: 8.r),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.r,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.r),
                    Row(
                      children: [
                        Icon(
                          Symbols.check_circle_rounded,
                          size: 10.r,
                          color: const Color(0xFF56C288),
                        ),
                        SizedBox(width: 3.r),
                        Text(
                          AppLocale.builtinPlayerReady.getString(context),
                          style: TextStyle(
                            fontSize: 10.r,
                            color: isSelected
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 6.r),
                        Text(
                          '($coreName)',
                          style: TextStyle(
                            fontSize: 9.r,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Symbols.check_rounded,
                  size: 14.r,
                  color: theme.colorScheme.secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
