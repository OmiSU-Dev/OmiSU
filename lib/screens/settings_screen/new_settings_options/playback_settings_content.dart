import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/services/embedded/play_settings_service.dart';
import 'package:omisu/services/launch/device_profile.dart';
import 'package:omisu/services/launch/device_profile_service.dart';
import 'package:omisu/services/launch/launch_tuning_resolver.dart';
import 'package:omisu/services/launch/launch_tuning_store.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/utils/adaptive_scroll.dart';
import 'package:omisu/widgets/custom_toggle_switch.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

import 'settings_title.dart';
import 'widgets/setting_row.dart';

class PlaybackSettingsContent extends StatefulWidget {
  final bool isContentFocused;
  final int selectedContentIndex;

  const PlaybackSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  @override
  State<PlaybackSettingsContent> createState() => PlaybackSettingsContentState();
}

class PlaybackSettingsContentState extends State<PlaybackSettingsContent> {
  int _simIndex = 0;
  PlaySettings _play = const PlaySettings();
  String _coresVersion = '';
  String _engineVersion = '';
  final ScrollController _scrollController = ScrollController();
  final AdaptiveScroller _scroller = AdaptiveScroller();
  final List<GlobalKey> _itemKeys =
      List.generate(_androidPlayRowCount + 1, (_) => GlobalKey());

  static const _simOptions = <(String, DeviceProfile?)>[
    ('Auto-detect', null),
    ('Simulate: Nord N30', DeviceProfileService.nordN30),
    ('Simulate: Android low', DeviceProfileService.androidLow),
    ('Simulate: Android mid', DeviceProfileService.androidMid),
  ];

  static const _androidPlayRowCount = 11;

  int getItemCount() {
    var count = Platform.isAndroid ? _androidPlayRowCount : 0;
    if (kDebugMode) count += 1;
    return count;
  }

  void scrollToIndex(int index) {
    _scroller.ensureVisibleIndex(
      index,
      keys: _itemKeys,
      controller: _scrollController,
    );
  }

  void selectItem(int index) {
    if (!Platform.isAndroid) return;
    SfxService().playEnterSound();
    switch (index) {
      case 0:
        _patchPlay((p) => p.copyWith(autosaveOnExit: !p.autosaveOnExit));
      case 1:
        _patchPlay((p) => p.copyWith(performanceMode: !p.performanceMode));
      case 2:
        if (!_play.performanceMode) {
          _patchPlay((p) => p.copyWith(hdMode: !p.hdMode));
        }
      case 3:
        if (_play.effectiveHdMode) _cycleHdQuality();
      case 4:
        if (_play.effectiveHdMode) {
          _patchPlay((p) => p.copyWith(adaptiveHdMode: !p.adaptiveHdMode));
        }
      case 5:
        if (!_play.performanceMode) {
          _patchPlay((p) => p.copyWith(immersiveMode: !p.immersiveMode));
        }
      case 6:
        _patchPlay((p) => p.copyWith(rumbleEnabled: !p.rumbleEnabled));
      case 7:
        _patchPlay((p) => p.copyWith(lowLatencyAudio: !p.lowLatencyAudio));
      case 8:
        unawaited(_setTouchControls(!_play.touchControlsEnabled));
      case 9:
        _patchPlay((p) => p.copyWith(showFpsCounter: !p.showFpsCounter));
      case 10:
        if (!_play.effectiveHdMode && !_play.performanceMode) _cycleShader();
      default:
        if (kDebugMode && index == getItemCount() - 1) {
          setState(() {
            _simIndex = (_simIndex + 1) % _simOptions.length;
            DeviceProfileService.instance.simulateProfile(
              _simOptions[_simIndex].$2,
            );
          });
        }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlaySettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaySettings() async {
    await PlaySettingsService.load();
    if (Platform.isAndroid) {
      _coresVersion = await EmbeddedEmulatorService.getBuiltinCoresVersion();
      _engineVersion =
          await EmbeddedEmulatorService.getBundledLibretroDroidVersion();
    }
    if (mounted) setState(() => _play = PlaySettingsService.current);
  }

  Future<void> _patchPlay(PlaySettings Function(PlaySettings) fn) async {
    await PlaySettingsService.update(fn);
    if (mounted) setState(() => _play = PlaySettingsService.current);
  }

  Future<void> _setTouchControls(bool enabled) async {
    await PlaySettingsService.markTouchControlsUserConfigured();
    await _patchPlay((p) => p.copyWith(touchControlsEnabled: enabled));
  }

  void _cycleShader() {
    final filters = PlaySettings.shaderFilters;
    final idx = filters.indexOf(_play.shaderFilter);
    final next = filters[(idx + 1) % filters.length];
    _patchPlay((p) => p.copyWith(shaderFilter: next));
  }

  void _cycleHdQuality() {
    final qualities = PlaySettings.hdModeQualities;
    final idx = qualities.indexOf(_play.hdModeQuality);
    final next = qualities[(idx + 1) % qualities.length];
    _patchPlay((p) => p.copyWith(hdModeQuality: next));
  }

  String _previewTuning() {
    final device = DeviceProfileService.instance.profile;
    final sample = LaunchTuningResolver.resolve(
      device: device,
      systemFolder: 'nes',
    );
    return 'NES sample: skipDup=${sample.skipDuplicateFrames}, '
        'vars=${sample.coreVariables.length}, '
        'corePref=${sample.corePreferenceKeyword ?? "none"}';
  }

  Widget _toggleRow({
    required int index,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.r),
      child: SettingRow(
        key: _itemKeys[index],
        title: title,
        subtitle: subtitle,
        focused: widget.isContentFocused && widget.selectedContentIndex == index,
        trailing: CustomToggleSwitch(
          value: value,
          disabled: !enabled,
          onChanged: enabled ? onChanged : null,
        ),
        onTap: enabled ? () => onChanged(!value) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = DeviceProfileService.instance.profile;
    final store = LaunchTuningStore.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.playback.getString(context),
          subtitle: AppLocale.playbackSubtitle.getString(context),
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
                if (Platform.isAndroid) ...[
                  Text(
                    'Built-in player',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.r),
                  OmisuRetroPanel(
                    padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                    child: Text(
                      'Cores: $_coresVersion\nEngine: LibretroDroid $_engineVersion\n'
                      'Auto-tune: ${DeviceProfileService.instance.detectedProfile.playbackAutoTuneLabel}'
                      '${DeviceProfileService.instance.isSimulated ? "\n(QA override: ${DeviceProfileService.instance.profile.id})" : ""}',
                      style: omisuRetroLabelStyle(
                        context,
                        size: 9,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.r),
                  _toggleRow(
                    index: 0,
                    title: 'Autosave on exit',
                    subtitle: 'Save state and battery data when leaving a game',
                    value: _play.autosaveOnExit,
                    onChanged: (v) => _patchPlay((p) => p.copyWith(autosaveOnExit: v)),
                  ),
                  _toggleRow(
                    index: 1,
                    title: 'Performance mode',
                    subtitle: _play.performanceMode
                        ? 'On — HD and heavy filters off at launch for a stable picture'
                        : 'Off — use HD and picture filters below',
                    value: _play.performanceMode,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(performanceMode: v)),
                  ),
                  _toggleRow(
                    index: 2,
                    title: 'HD mode',
                    subtitle: _play.performanceMode
                        ? 'Disabled while Performance mode is on'
                        : 'Sharpen pixel art (also in-game ☰ menu)',
                    value: _play.effectiveHdMode,
                    enabled: !_play.performanceMode,
                    onChanged: (v) => _patchPlay((p) => p.copyWith(hdMode: v)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.r),
                    child: SettingRow(
                      key: _itemKeys[3],
                      title: 'HD quality',
                      subtitle: _play.effectiveHdMode
                          ? 'Upscaler: ${_play.hdModeQualityLabel}'
                          : _play.performanceMode
                              ? 'Performance mode — HD off'
                              : 'Enable HD mode to adjust',
                      focused: widget.isContentFocused &&
                          widget.selectedContentIndex == 3,
                      trailing: Icon(
                        Symbols.high_quality_rounded,
                        color: _play.effectiveHdMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        size: 20.r,
                      ),
                      onTap: _play.effectiveHdMode ? _cycleHdQuality : null,
                    ),
                  ),
                  _toggleRow(
                    index: 4,
                    title: 'Adaptive HD',
                    subtitle: _play.effectiveHdMode
                        ? 'Lower upscaler quality if FPS drops'
                        : 'Enable HD mode to use',
                    value: _play.effectiveAdaptiveHdMode,
                    enabled: _play.effectiveHdMode,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(adaptiveHdMode: v)),
                  ),
                  _toggleRow(
                    index: 5,
                    title: 'Immersive display',
                    subtitle: _play.performanceMode
                        ? 'Disabled while Performance mode is on'
                        : 'Blend game edges into the screen bezel',
                    value: _play.effectiveImmersiveMode,
                    enabled: !_play.performanceMode,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(immersiveMode: v)),
                  ),
                  _toggleRow(
                    index: 6,
                    title: 'Rumble',
                    subtitle: 'Forward controller rumble to device vibration',
                    value: _play.rumbleEnabled,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(rumbleEnabled: v)),
                  ),
                  _toggleRow(
                    index: 7,
                    title: 'Low-latency audio',
                    subtitle: 'Reduce audio delay on supported devices',
                    value: _play.lowLatencyAudio,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(lowLatencyAudio: v)),
                  ),
                  _toggleRow(
                    index: 8,
                    title: 'Touch controls',
                    subtitle: 'Show on-screen D-pad and buttons during play',
                    value: _play.touchControlsEnabled,
                    onChanged: (v) => unawaited(_setTouchControls(v)),
                  ),
                  _toggleRow(
                    index: 9,
                    title: 'FPS counter',
                    subtitle: 'Show live frame rate in the top-left while playing',
                    value: _play.showFpsCounter,
                    onChanged: (v) =>
                        _patchPlay((p) => p.copyWith(showFpsCounter: v)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.r),
                    child: SettingRow(
                      key: _itemKeys[10],
                      title: 'Picture filter',
                      subtitle: _play.performanceMode
                          ? 'Performance mode uses a light sharp filter'
                          : 'Shader: ${_play.shaderFilter}',
                      focused: widget.isContentFocused &&
                          widget.selectedContentIndex == 10,
                      trailing: Icon(
                        Symbols.tune_rounded,
                        color: _play.effectiveHdMode
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                            : theme.colorScheme.primary,
                        size: 20.r,
                      ),
                      onTap: (_play.effectiveHdMode || _play.performanceMode)
                          ? null
                          : _cycleShader,
                    ),
                  ),
                  SizedBox(height: 8.r),
                ],
                OmisuRetroPanel(
                  padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Symbols.memory_rounded,
                        size: 16.r,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8.r),
                      Expanded(
                        child: Text(
                          'Auto-tuning: on\n'
                          'Device: ${device.id} (${device.tier.name}'
                          '${device.isKnownTarget ? ", target build" : ""})\n'
                          '${_previewTuning()}',
                          style: omisuRetroLabelStyle(
                            context,
                            size: 9,
                            weight: FontWeight.w500,
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
                OmisuRetroPanel(
                  padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Symbols.history_rounded,
                        size: 16.r,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8.r),
                      Expanded(
                        child: Text(
                          'Last launch:\n${store.summary()}',
                          style: omisuRetroLabelStyle(
                            context,
                            size: 9,
                            weight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: 12.r),
                  OmisuRetroPanel(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.r,
                      vertical: 8.r,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.science_rounded,
                          size: 16.r,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8.r),
                        Expanded(
                          child: Text(
                            'Debug device profile: ${_simOptions[_simIndex].$1}',
                            style: omisuRetroLabelStyle(
                              context,
                              size: 9,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12.r),
                OmisuRetroPanel(
                  padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
                  child: Text(
                    AppLocale.playbackEmbeddedNote.getString(context),
                    style: omisuRetroLabelStyle(
                      context,
                      size: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
