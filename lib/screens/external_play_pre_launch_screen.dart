import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omisu/services/streaming/stream_settings_service.dart';
import 'package:omisu/widgets/embedded/external_stream_overlay_menu.dart';

/// User choice from the pre-launch stream sheet (Android Apps grid).
class ExternalPlayPreLaunchResult {
  const ExternalPlayPreLaunchResult({required this.startStream});

  final bool startStream;
}

/// Pre-launch stream options before opening a Play Store / Android app.
class ExternalPlayPreLaunchScreen extends StatefulWidget {
  const ExternalPlayPreLaunchScreen({
    super.key,
    required this.gameTitle,
    required this.packageName,
  });

  final String gameTitle;
  final String packageName;

  @override
  State<ExternalPlayPreLaunchScreen> createState() =>
      _ExternalPlayPreLaunchScreenState();
}

class _ExternalPlayPreLaunchScreenState extends State<ExternalPlayPreLaunchScreen> {
  StreamSettings _settings = const StreamSettings();
  bool _streamOnLaunch = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await StreamSettingsService.ensureStreamCredentials();
    final onLaunch = await StreamSettingsService.getStreamOnLaunch(
      widget.packageName,
    );
    if (!mounted) return;
    setState(() {
      _settings = StreamSettingsService.current;
      _streamOnLaunch = onLaunch;
    });
  }

  Future<void> _cancel() async {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmLaunch() async {
    await StreamSettingsService.save(_settings);
    await StreamSettingsService.setStreamOnLaunch(
      widget.packageName,
      _streamOnLaunch,
    );
    if (!mounted) return;
    final startStream = _streamOnLaunch && _settings.isConfigured;
    Navigator.of(context).pop(
      ExternalPlayPreLaunchResult(startStream: startStream),
    );
  }

  Future<void> _saveSettings(StreamSettings next) async {
    setState(() => _settings = next);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_cancel());
      },
      child: Material(
        color: Colors.black,
        child: ExternalStreamOverlayMenu(
          gameTitle: widget.gameTitle,
          preLaunch: true,
          streamOnLaunch: _streamOnLaunch,
          streamConfigured: _settings.isConfigured,
          gameAudioEnabled: _settings.gameAudioEnabled,
          includeMicrophone: _settings.includeMicrophone,
          faceCamEnabled: _settings.faceCamEnabled,
          onLaunch: () => unawaited(_confirmLaunch()),
          onCancel: () => unawaited(_cancel()),
          onToggleStreamOnLaunch: () {
            if (!_settings.isConfigured) return;
            setState(() => _streamOnLaunch = !_streamOnLaunch);
          },
          onToggleGameAudio: () => unawaited(
            _saveSettings(
              _settings.copyWith(gameAudioEnabled: !_settings.gameAudioEnabled),
            ),
          ),
          onToggleIncludeMic: () => unawaited(
            _saveSettings(
              _settings.copyWith(
                includeMicrophone: !_settings.includeMicrophone,
              ),
            ),
          ),
          onToggleFaceCam: () => unawaited(
            _saveSettings(
              _settings.copyWith(faceCamEnabled: !_settings.faceCamEnabled),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the pre-launch sheet on the current navigator.
class ExternalPlayPreLaunchFlow {
  ExternalPlayPreLaunchFlow._();

  static bool _showing = false;

  static bool get isShowing => _showing;

  static Future<ExternalPlayPreLaunchResult?> show(
    BuildContext context, {
    required String gameTitle,
    required String packageName,
  }) async {
    if (!Platform.isAndroid || _showing) return null;
    _showing = true;
    try {
      return await Navigator.of(context).push<ExternalPlayPreLaunchResult>(
        PageRouteBuilder<ExternalPlayPreLaunchResult>(
          opaque: true,
          fullscreenDialog: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              ExternalPlayPreLaunchScreen(
                gameTitle: gameTitle,
                packageName: packageName,
              ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } finally {
      _showing = false;
    }
  }
}
