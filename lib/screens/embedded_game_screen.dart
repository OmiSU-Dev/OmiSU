import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:omisu/models/embedded_core_config.dart';
import 'package:omisu/models/game_model.dart';
import 'package:omisu/models/system_model.dart';
import 'package:omisu/services/embedded/embedded_audio_session.dart';
import 'package:omisu/services/embedded/embedded_core_option_allowlist.dart';
import 'package:omisu/services/embedded/embedded_emulator_service.dart';
import 'package:omisu/services/embedded/embedded_launch_status.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/services/embedded/embedded_exit_destination.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/repositories/game_repository.dart';
import 'package:omisu/services/embedded/play_settings_service.dart';
import 'package:omisu/services/launch/launch_tuning_merge.dart';
import 'package:omisu/services/streaming/stream_settings_service.dart';
import 'package:omisu/services/streaming/streaming_service.dart';
import 'package:omisu/services/game/favorites_service.dart';
import 'package:omisu/services/game/game_session_manager.dart';
import 'package:omisu/services/gamepad/gamepad_navigation_manager.dart';
import 'package:omisu/utils/gamepad_nav.dart';
import 'package:omisu/services/launch/device_profile_service.dart';
import 'package:omisu/services/launch/launch_tuning.dart';
import 'package:omisu/services/launch/launch_tuning_resolver.dart';
import 'package:omisu/services/logger_service.dart';
import 'package:omisu/widgets/embedded/embedded_core_options_sheet.dart';
import 'package:omisu/widgets/embedded/embedded_play_settings_sheet.dart';
import 'package:omisu/widgets/embedded/embedded_pause_menu.dart';
import 'package:omisu/widgets/embedded/embedded_touch_overlay.dart';
import 'package:omisu/utils/root_navigator_key.dart';

class EmbeddedGameScreen extends StatefulWidget {
  final SystemModel system;
  final GameModel game;

  const EmbeddedGameScreen({
    super.key,
    required this.system,
    required this.game,
  });

  @override
  State<EmbeddedGameScreen> createState() => _EmbeddedGameScreenState();
}

class _EmbeddedGameScreenState extends State<EmbeddedGameScreen>
    with WidgetsBindingObserver {
  static final _log = LoggerService.instance;

  void _launchTrace(String phase, [String detail = '']) {
    _log.i(
      detail.isEmpty ? '[LaunchTrace] $phase' : '[LaunchTrace] $phase | $detail',
    );
  }
  bool _menuVisible = false;
  bool _loading = true;
  EmbeddedLaunchStatus _loadingStatus = EmbeddedLaunchStatus.initial;
  bool _coreReady = false;
  String? _launchError;
  bool _muted = false;
  bool _fastForward = false;
  bool _touchControlsEnabled = false;
  bool _gamepadConnected = false;
  bool _showFpsCounter = false;
  bool _hdMode = false;
  String _hdModeQuality = 'medium';
  String _shaderFilter = 'auto';
  String? _currentFps;
  Map<int, EmbeddedSaveSlotInfo> _slotInfo = const {};
  EmbeddedSaveSlotInfo _autosaveInfo = const EmbeddedSaveSlotInfo(hasSave: false);
  StreamSubscription<dynamic>? _statusSub;
  late LaunchTuning _tuning;
  Map<String, dynamic>? _embeddedParams;
  bool _exitTeardownStarted = false;
  OverlayEntry? _topChromeEntry;
  bool _streamOnLaunch = false;
  bool _streamStartAttempted = false;
  bool _isStreaming = false;
  StreamSubscription<StreamingLifecycleState>? _streamStateSub;
  late final GamepadNavigation _inGameGamepadNav;
  List<({String code, bool enabled})> _pendingLaunchCheats = const [];
  late final Key _embeddedPlatformViewKey;

  String get _embeddedSystemFolder =>
      widget.game.systemFolderName ?? widget.system.folderName;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _topChromeEntry?.markNeedsBuild();
  }

  void _syncTopChromeOverlay() {
    if (!mounted || _launchError != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _launchError != null) return;
      final overlay = rootNavigatorKey.currentState?.overlay;
      if (overlay == null) {
        return;
      }
      final inserting = _topChromeEntry == null;
      _topChromeEntry ??= OverlayEntry(
        opaque: false,
        builder: (ctx) => _buildTopChrome(ctx),
      );
      if (inserting) {
        overlay.insert(_topChromeEntry!);
      } else {
        _topChromeEntry!.markNeedsBuild();
      }
    });
  }

  void _removeTopChromeOverlay() {
    _topChromeEntry?.remove();
    _topChromeEntry = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _embeddedPlatformViewKey = ValueKey<String>(
      'embedded-pv-${widget.game.romPath ?? widget.game.romname}',
    );
    final detected = DeviceProfileService.instance.detectedProfile;
    _tuning = LaunchTuningResolver.resolve(
      device: detected,
      systemFolder: widget.system.folderName,
    );
    _log.i(
      '[LaunchTune] embedded/${widget.system.folderName}/${widget.game.romname}: '
      'profile=${_tuning.profileId}',
    );
    _inGameGamepadNav = GamepadNavigation(
      onSettings: () => unawaited(_openPauseMenu()),
    );
    _inGameGamepadNav.initialize();
    GamepadNavigationManager.pushLayer(
      'embedded_game',
      onActivate: _activateInGameGamepadIfNeeded,
      onDeactivate: () => _inGameGamepadNav.deactivate(),
    );
    _statusSub = EmbeddedEmulatorService.events.listen(_onEmbeddedStatus);
    if (Platform.isAndroid) {
      _streamStateSub = StreamingService.stateChanges.listen((state) {
        if (!mounted) return;
        setState(() => _isStreaming = state == StreamingLifecycleState.live);
        _syncTopChromeOverlay();
      });
    }
    _syncTopChromeOverlay();
    unawaited(_bootstrapEmbeddedSession());
  }

  Future<void> _bootstrapEmbeddedSession() async {
    try {
      await EmbeddedAudioSession.enter();
      await PlaySettingsService.load();
      if (Platform.isAndroid) {
        await StreamSettingsService.ensureStreamCredentials();
        _streamOnLaunch = await StreamSettingsService.getStreamOnLaunch(
          widget.game.romPath ?? widget.game.romname,
        );
      }
      await _refreshGamepadPresence();

      Map<String, String> perGameVars = const {};
      List<({String code, bool enabled})> launchCheats = const [];
      try {
        final saved = await GameRepository.getEmbeddedCoreVariables(
          _embeddedSystemFolder,
          widget.game.romname,
        );
        final allowed = allowedCoreOptionKeysFor(_embeddedSystemFolder);
        perGameVars = Map.fromEntries(
          saved.entries.where((e) => allowed.contains(e.key)),
        );
        final cheats = await GameRepository.getRomCheats(
          _embeddedSystemFolder,
          widget.game.romname,
        );
        launchCheats = cheats
            .map((c) => (code: c.code, enabled: c.enabled))
            .toList();
        unawaited(_syncCheatsInBackground());
      } catch (e, st) {
        _log.w(
          'Per-game play settings skipped for ${widget.game.romname}: $e\n$st',
        );
      }

      _tuning = mergeLaunchTuning(
        base: _tuning,
        perGameCoreVariables: perGameVars,
      );
      final play = PlaySettingsService.current;
      final detected = DeviceProfileService.instance.detectedProfile;
      final params = _tuning.toEmbeddedParamsWithPlay(
        play.toEmbeddedParams(device: detected),
      );
      final effectivePerf = play.effectivePerformanceMode(detected);
      _log.i(
        '[LaunchTune] embedded/$_embeddedSystemFolder/${widget.game.romname}: '
        'perf=$effectivePerf (pref=${play.performanceMode}) hdMode=${play.effectiveHdModeFor(detected)} '
        'hdQuality=${play.hdModeQuality} shader=${play.shaderFilter} '
        'perGameVars=${perGameVars.length} cheats=${launchCheats.length}',
      );
      final source = DeviceProfileService.instance.profileSource;
      _launchTrace(
        'flutter_tuning',
        'detected=${detected.id} model=${detected.model} '
        'ram=${detected.ramGb} tier=${detected.tier.name} source=${source.name} '
        'perfPref=${play.performanceMode} perfLaunch=$effectivePerf '
        'hd=${play.effectiveHdModeFor(detected)} hdQ=${play.hdModeQuality} '
        'shader=${params['shaderFilter']}',
      );
      if (play.immersiveMode) {
        unawaited(
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        );
      }
      if (!mounted) return;
      setState(() {
        _embeddedParams = params;
        _pendingLaunchCheats = launchCheats;
        _touchControlsEnabled = play.touchControlsEnabled;
        _showFpsCounter = play.showFpsCounter;
        _hdMode = play.effectiveHdModeFor(detected);
        _hdModeQuality = play.hdModeQuality;
        _shaderFilter = play.shaderFilter;
      });
      await _prepareEmbeddedLaunch();
    } catch (e, st) {
      _log.e('Embedded bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _launchError =
            e is PlatformException
                ? (e.message ??
                    'Could not start the built-in player. Try again.')
                : e.toString();
      });
    }
  }

  Future<void> _applyLaunchCheats() async {
    if (_pendingLaunchCheats.isEmpty || !Platform.isAndroid) return;
    try {
      await EmbeddedEmulatorService.applyCheats(_pendingLaunchCheats);
    } catch (e, st) {
      _log.w('Launch cheat apply failed: $e\n$st');
    }
  }

  /// Libretro `.cht` import can scan thousands of files — never block core startup.
  Future<void> _syncCheatsInBackground() async {
    try {
      final displayName = widget.game.name.isNotEmpty
          ? widget.game.name
          : widget.game.realname;
      await GameRepository.syncCheatsFromSources(
        systemFolderName: _embeddedSystemFolder,
        romname: widget.game.romname,
        romPath: widget.game.romPath,
        displayName: displayName,
        titleName: widget.game.titleName ?? widget.game.realname,
      );
      final cheats = await GameRepository.getRomCheats(
        _embeddedSystemFolder,
        widget.game.romname,
      );
      final payloads = cheats
          .map((c) => (code: c.code, enabled: c.enabled))
          .toList();
      if (!mounted) return;
      _pendingLaunchCheats = payloads;
      await _applyLaunchCheats();
    } catch (e, st) {
      _log.w('Background cheat sync failed for ${widget.game.romname}: $e\n$st');
    }
  }

  Future<void> _prepareEmbeddedLaunch() async {
    try {
      await EmbeddedEmulatorService.ensureCoreIdle();
      await EmbeddedEmulatorService.ensureCoreReady(
        _embeddedSystemFolder,
        romPath: widget.game.romPath,
      );
      if (!mounted) return;
      setState(() => _coreReady = true);
      _launchTrace('core_ready', 'system=${widget.system.folderName}');
      _syncTopChromeOverlay();
      _activateInGameGamepadIfNeeded();
    } on PlatformException catch (e) {
      _log.e('Embedded core prepare failed: ${e.message}');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _launchError =
            e.message ??
            'Could not prepare the built-in player. Check your network and try again.';
      });
    } catch (e) {
      _log.e('Embedded core prepare failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _launchError = e.toString();
      });
    }
  }

  Future<void> _refreshGamepadPresence() async {
    final connected = Platform.isAndroid
        ? await EmbeddedEmulatorService.hasPhysicalGamepad()
        : (await GamepadNavigation.getConnectedGamepads()).isNotEmpty;
    if (!mounted || connected == _gamepadConnected) return;
    setState(() => _gamepadConnected = connected);
  }

  Future<void> _syncFpsCounter() async {
    if (!Platform.isAndroid) return;
    await EmbeddedEmulatorService.setFpsCounterEnabled(_showFpsCounter);
  }

  void _onEmbeddedStatus(dynamic event) {
    if (event is! Map) return;
    final type = event['type']?.toString();
    if (type != 'status') return;
    final message = event['message']?.toString();
    if (message == null || message.isEmpty || !mounted) return;
    if (message == 'ready') {
      _launchTrace('native_status', 'ready');
      setState(() => _loading = false);
      _syncTopChromeOverlay();
      _activateInGameGamepadIfNeeded();
      unawaited(_syncFpsCounter());
      unawaited(EmbeddedEmulatorService.setAudioEnabled(!_muted));
      if (_menuVisible) {
        unawaited(EmbeddedEmulatorService.setEmulationPaused(true));
      }
      unawaited(_maybeAutoStartStream());
      return;
    }
    if (message == 'presenting') {
      _launchTrace('native_status', 'presenting');
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
      unawaited(EmbeddedEmulatorService.nudgePresentation());
      return;
    }
    if (message.startsWith('fps:')) {
      if (!_showFpsCounter || !mounted) return;
      _currentFps = message.substring('fps:'.length);
      _topChromeEntry?.markNeedsBuild();
      return;
    }
    if (message.startsWith('error:')) {
      final code = message.substring('error:'.length);
      _log.e('Embedded GLRetro error code=$code');
      _launchTrace('native_status', 'error=$code');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _launchError = 'Built-in player failed to run this game (error $code).';
      });
      return;
    }
    setState(() => _loadingStatus = EmbeddedLaunchStatus.fromNativeMessage(message));
  }

  Future<void> _maybeAutoStartStream() async {
    if (!Platform.isAndroid || !_streamOnLaunch || _streamStartAttempted) {
      return;
    }
    _streamStartAttempted = true;
    await _startStream();
  }

  Future<void> _startStream() async {
    if (!Platform.isAndroid) return;
    await StreamSettingsService.ensureStreamCredentials();
    if (!StreamSettingsService.current.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.streamingSetupRequired.getString(context)),
          ),
        );
      }
      return;
    }
    try {
      await StreamingService.startFromSettings();
    } on PlatformException catch (e) {
      _log.w('Stream start failed: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Stream failed')),
        );
      }
    }
  }

  Future<void> _stopStream() async {
    if (!Platform.isAndroid) return;
    await StreamingService.stopStream();
    if (mounted) setState(() => _isStreaming = false);
  }

  Future<void> _toggleStream() async {
    if (_isStreaming) {
      await _stopStream();
    } else {
      await _startStream();
    }
  }

  Future<void> _releaseStreamingAndAudio() async {
    await StreamingService.stopStream();
    await EmbeddedAudioSession.exit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_menuVisible) return;
    unawaited(EmbeddedEmulatorService.setEmulationPaused(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSub?.cancel();
    _streamStateSub?.cancel();
    if (Platform.isAndroid && !_exitTeardownStarted) {
      unawaited(_releaseStreamingAndAudio());
    }
    _removeTopChromeOverlay();
    unawaited(EmbeddedEmulatorService.setFpsCounterEnabled(false));
    if (!_exitTeardownStarted && _coreReady) {
      unawaited(EmbeddedEmulatorService.unload());
    }
    GamepadNavigationManager.popLayer('embedded_game');
    _inGameGamepadNav.dispose();
    unawaited(EmbeddedEmulatorService.setRouteGamepadToCore(true));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  void _activateInGameGamepadIfNeeded() {
    if (!Platform.isAndroid || _menuVisible || _loading || !_coreReady) {
      return;
    }
    _inGameGamepadNav.activate();
  }

  void _closePauseMenu() {
    if (!_menuVisible) return;
    setState(() => _menuVisible = false);
    unawaited(EmbeddedEmulatorService.setEmulationPaused(false));
    unawaited(EmbeddedEmulatorService.setRouteGamepadToCore(true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activateInGameGamepadIfNeeded();
    });
  }

  Future<void> _exitGame() async {
    if (_exitTeardownStarted) return;
    EmbeddedExitHandler.markPendingHome();
    _exitTeardownStarted = true;
    // Remount systems/games UI before pop — they hide with SizedBox.shrink during play.
    _removeTopChromeOverlay();
    EmbeddedExitHandler.revealHomeUnderEmbeddedExit();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    // Finish native save/teardown before popping so it does not race navigation.
    await StreamingService.stopStream();
    await EmbeddedEmulatorService.unload();
    await EmbeddedEmulatorService.ensureCoreIdle();
    await EmbeddedAudioSession.exit();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _refreshSlotInfo() async {
    final slots = <int, EmbeddedSaveSlotInfo>{};
    for (var slot = 1; slot <= 4; slot++) {
      final hasSave = await EmbeddedEmulatorService.hasStateSlot(slot: slot);
      final preview = hasSave
          ? await EmbeddedEmulatorService.getStatePreview(slot: slot)
          : null;
      slots[slot] = EmbeddedSaveSlotInfo(
        hasSave: hasSave,
        previewBytes: preview,
      );
    }
    final autosaveHas = await EmbeddedEmulatorService.hasStateSlot(slot: 0);
    if (mounted) {
      setState(() {
        _slotInfo = slots;
        _autosaveInfo = EmbeddedSaveSlotInfo(hasSave: autosaveHas);
      });
    }
  }

  void _togglePauseMenu() {
    if (_menuVisible) {
      _closePauseMenu();
      return;
    }
    unawaited(_openPauseMenu());
  }

  Future<void> _openPauseMenu() async {
    if (_menuVisible) return;
    _inGameGamepadNav.deactivate();
    if (Platform.isAndroid) {
      await EmbeddedEmulatorService.setEmulationPaused(true);
      await EmbeddedEmulatorService.setRouteGamepadToCore(false);
    }
    setState(() => _menuVisible = true);
    await Future.wait([_refreshSlotInfo(), _refreshGamepadPresence()]);
  }

  Future<void> _saveSlot(int slot) async {
    final ok = await EmbeddedEmulatorService.saveState(slot: slot);
    if (!mounted) return;
    if (ok) {
      if (slot == 0) {
        setState(() => _autosaveInfo = const EmbeddedSaveSlotInfo(hasSave: true));
      } else {
        final preview = await EmbeddedEmulatorService.getStatePreview(slot: slot);
        setState(() {
          _slotInfo = {
            ..._slotInfo,
            slot: EmbeddedSaveSlotInfo(hasSave: true, previewBytes: preview),
          };
        });
      }
    }
    _toast(
      ok
          ? (slot == 0 ? 'Autosave updated' : 'Saved to slot $slot')
          : 'Save failed',
    );
  }

  Future<void> _loadSlot(int slot) async {
    final ok = await EmbeddedEmulatorService.loadState(slot: slot);
    if (!mounted) return;
    _closePauseMenu();
    _toast(
      ok
          ? (slot == 0 ? 'Loaded autosave' : 'Loaded slot $slot')
          : (slot == 0 ? 'No autosave yet' : 'No save in slot $slot'),
    );
  }

  Future<void> _toggleMute() async {
    _muted = !_muted;
    await EmbeddedEmulatorService.setAudioEnabled(!_muted);
    if (mounted) setState(() {});
  }

  Future<void> _toggleFastForward() async {
    _fastForward = !_fastForward;
    await EmbeddedEmulatorService.setFastForward(_fastForward);
    if (mounted) setState(() {});
  }

  Future<void> _toggleTouchControls() async {
    _touchControlsEnabled = !_touchControlsEnabled;
    await PlaySettingsService.markTouchControlsUserConfigured();
    await PlaySettingsService.update(
      (p) => p.copyWith(touchControlsEnabled: _touchControlsEnabled),
    );
    if (mounted) setState(() {});
  }

  Future<void> _syncDisplaySettings() async {
    if (!Platform.isAndroid) return;
    final play = PlaySettingsService.current;
    await EmbeddedEmulatorService.applyDisplaySettings(
      systemId: widget.system.folderName,
      hdMode: _hdMode,
      hdModeQuality: _hdModeQuality,
      adaptiveHdMode: play.adaptiveHdMode,
      shaderFilter: _shaderFilter,
    );
  }

  Future<void> _toggleFpsCounter() async {
    _showFpsCounter = !_showFpsCounter;
    if (!_showFpsCounter) {
      _currentFps = null;
    }
    await PlaySettingsService.update(
      (p) => p.copyWith(showFpsCounter: _showFpsCounter),
    );
    await _syncFpsCounter();
    if (mounted) setState(() {});
  }

  Future<void> _toggleHdMode() async {
    _hdMode = !_hdMode;
    await PlaySettingsService.update((p) => p.copyWith(hdMode: _hdMode));
    await _syncDisplaySettings();
    if (mounted) setState(() {});
  }

  Future<void> _resetGame() async {
    await EmbeddedEmulatorService.reset();
    if (!mounted) return;
    _closePauseMenu();
    _toast('Game reset');
  }

  Future<void> _sendStartFromPauseMenu() async {
    _closePauseMenu();
    await EmbeddedEmulatorService.tapStartButton();
  }

  Future<void> _openGameOptions() async {
    await EmbeddedCoreOptionsSheet.show(
      context,
      systemFolder: _embeddedSystemFolder,
    );
  }

  Future<void> _openPlaySettings() async {
    await EmbeddedPlaySettingsSheet.show(
      context,
      game: widget.game,
      system: widget.system,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final romPath = widget.game.romPath;
    if (romPath == null || romPath.isEmpty) {
      return _buildScaffold(
        Center(
          child: Text(
            'Missing ROM path',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    if (_launchError != null) {
      return _buildScaffold(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not start game',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _launchError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _exitGame,
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildScaffold(
      Stack(
        fit: StackFit.expand,
        children: [
          if (Platform.isAndroid && _coreReady && _embeddedParams != null)
            Positioned.fill(
              child: _buildEmbeddedRetroView(romPath),
            )
          else if (!Platform.isAndroid)
            _buildLaunchStatusCard(EmbeddedLaunchStatus.desktopUnsupported)
          else
            const ColoredBox(color: Colors.black),
          if (_loading) _buildLoadingOverlay(),
          if (_menuVisible)
            EmbeddedPauseMenu(
              gameTitle: widget.game.name,
              muted: _muted,
              fastForward: _fastForward,
              touchControlsEnabled: _touchControlsEnabled,
              showFpsCounter: _showFpsCounter,
              hdMode: _hdMode,
              slotInfo: _slotInfo,
              autosaveInfo: _autosaveInfo,
              onResume: _closePauseMenu,
              onSendStartButton: () => unawaited(_sendStartFromPauseMenu()),
              onReset: _resetGame,
              onToggleMute: _toggleMute,
              onToggleFastForward: _toggleFastForward,
              onToggleTouchControls: _toggleTouchControls,
              onToggleFpsCounter: _toggleFpsCounter,
              onToggleHdMode: _toggleHdMode,
              onSaveSlot: _saveSlot,
              onLoadSlot: _loadSlot,
              onSaveAutosave: () => _saveSlot(0),
              onLoadAutosave: () => _loadSlot(0),
              onOpenGameOptions: _openGameOptions,
              onOpenPlaySettings:
                  EmbeddedCoreRegistry.supports(_embeddedSystemFolder)
                      ? _openPlaySettings
                      : null,
              onExitToHome: _exitGame,
              showStreamingControls: Platform.isAndroid,
              isStreaming: _isStreaming,
              onToggleStream: Platform.isAndroid ? () => unawaited(_toggleStream()) : null,
            ),
          if (Platform.isAndroid &&
              _touchControlsEnabled &&
              !_menuVisible &&
              !_loading)
            EmbeddedTouchOverlay(systemId: widget.system.folderName),
        ],
      ),
    );
  }

  /// Top chrome lives in the root overlay so it stays above the hybrid-composition
  /// GL surface on every launch (route OverlayPortal can render underneath).
  Widget _buildTopChrome(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
        if (_isStreaming && !_loading && !_menuVisible)
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  AppLocale.streamingLive.getString(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        if (_showFpsCounter && !_loading && !_menuVisible)
          Positioned(
            top: 12,
            left: _isStreaming ? 72 : 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${_currentFps ?? '…'} FPS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: _menuVisible ? 'Resume' : 'Pause menu',
              onPressed: _togglePauseMenu,
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildEmbeddedRetroView(String romPath) {
    // GLSurfaceView (LibretroDroid) must use hybrid composition. Flutter's
    // default AndroidView texture-layer mode leaves the GL surface black.
    return Builder(
      builder: (context) {
        final layoutDirection =
            Directionality.maybeOf(context) ?? TextDirection.ltr;
        final creationParams = <String, dynamic>{
          'systemId': _embeddedSystemFolder,
          'romPath': romPath,
          'tuning': _embeddedParams!,
        };
        return PlatformViewLink(
          key: _embeddedPlatformViewKey,
          viewType: 'embedded-retro-view',
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers:
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (params) {
            final controller = PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: 'embedded-retro-view',
              layoutDirection: layoutDirection,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            );
            controller.addOnPlatformViewCreatedListener((id) {
              params.onPlatformViewCreated(id);
              _log.i(
                'Embedded retro view created (hybrid) for '
                '${widget.system.folderName}',
              );
              _launchTrace(
                'platform_view_created',
                'system=${widget.system.folderName} hybrid=true',
              );
              _syncTopChromeOverlay();
              if (mounted && _loading) {
                setState(() => _loading = false);
              }
              unawaited(_syncFpsCounter());
              unawaited(_applyLaunchCheats());
              unawaited(_maybeAutoStartStream());
            });
            controller.create();
            return controller;
          },
        );
      },
    );
  }

  Widget _buildLaunchStatusCard(EmbeddedLaunchStatus status) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildLaunchStatusText(status),
        ),
      ),
    );
  }

  Widget _buildLaunchStatusText(EmbeddedLaunchStatus status) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          status.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'JetBrainsMonoNerdFont',
            color: OmisuAccent.brandGreen,
            fontSize: 14,
            letterSpacing: 0.4,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          status.detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrainsMonoNerdFont',
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
            letterSpacing: 0.2,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: OmisuAccent.brandGreen,
            ),
            const SizedBox(height: 20),
            _buildLaunchStatusText(_loadingStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold(Widget body) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_exitGame());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: body,
      ),
    );
  }
}

Future<bool> launchEmbeddedGame(
  BuildContext context,
  SystemModel system,
  GameModel game,
) async {
  if (game.romPath == null) return false;

  await PlaySettingsService.load();
  GameSessionManager.registerGameLaunch(system, game, 'embedded_${system.folderName}');
  await FavoritesService.recordGamePlayed(game);

  if (!context.mounted) return false;

  // Ensure any prior embedded session is fully torn down before loading a new core.
  await EmbeddedEmulatorService.unload();
  await EmbeddedEmulatorService.ensureCoreIdle();

  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return false;

  await navigator.push(
    MaterialPageRoute(
      builder: (_) => EmbeddedGameScreen(system: system, game: game),
      fullscreenDialog: true,
    ),
  );
  return true;
}
