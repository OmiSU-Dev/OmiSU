import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omisu/services/streaming/stream_settings_service.dart';

enum StreamingLifecycleState { idle, starting, live, error }

class StreamingService {
  StreamingService._();

  static const _channel = MethodChannel('com.omisu.launcher/streaming');
  static const _events = EventChannel('com.omisu.launcher/streaming_events');

  static Stream<dynamic>? _eventStream;
  static final _stateController =
      StreamController<StreamingLifecycleState>.broadcast();

  static Stream<StreamingLifecycleState> get stateChanges =>
      _stateController.stream;

  static StreamingLifecycleState _state = StreamingLifecycleState.idle;

  static StreamingLifecycleState get state => _state;

  static String? _lastError;

  static String? get lastError => _lastError;

  static Stream<dynamic> get events {
    _eventStream ??= _events.receiveBroadcastStream();
    return _eventStream!;
  }

  static Future<void> init() async {
    if (!StreamSettingsService.isSupported) return;
    events.listen(_handleEvent);
    await refreshStatus();
  }

  static void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final map = Map<String, dynamic>.from(event);
    if (map['type'] != 'state') return;
    final raw = map['state']?.toString() ?? 'idle';
    _lastError = map['message']?.toString();
    _state = switch (raw) {
      'live' => StreamingLifecycleState.live,
      'starting' => StreamingLifecycleState.starting,
      'error' => StreamingLifecycleState.error,
      _ => StreamingLifecycleState.idle,
    };
    _stateController.add(_state);
  }

  static Future<void> refreshStatus() async {
    if (!StreamSettingsService.isSupported) return;
    try {
      final status = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStatus');
      if (status == null) return;
      _handleEvent({
        'type': 'state',
        'state': status['state'],
        'message': status['message'],
      });
    } catch (e) {
      debugPrint('StreamingService.refreshStatus: $e');
    }
  }

  static Future<bool> isStreaming() async {
    if (!StreamSettingsService.isSupported) return false;
    final result = await _channel.invokeMethod<bool>('isStreaming');
    return result ?? false;
  }

  static Future<bool> startFromSettings() async {
    if (!StreamSettingsService.isSupported) return false;
    final settings = await StreamSettingsService.ensureStreamCredentials();
    if (!settings.isConfigured) {
      throw StateError('Streaming is not configured');
    }
    return startWithUri(
      ingestUri: settings.ingestUri,
      width: settings.width,
      height: settings.height,
      bitrateKbps: settings.bitrateKbps,
      faceCamEnabled: settings.faceCamEnabled,
      faceCamCorner: settings.faceCamCorner,
      faceCamSize: settings.faceCamSize,
      audioMode: settings.audioMode,
    );
  }

  static Future<bool> startWithUri({
    required String ingestUri,
    int width = 1280,
    int height = 720,
    int bitrateKbps = 2500,
    int fps = 30,
    String audioMode = 'game',
    bool faceCamEnabled = false,
    String faceCamCorner = 'bottomRight',
    String faceCamSize = 'medium',
  }) async {
    if (!StreamSettingsService.isSupported) return false;
    if (audioMode == 'game' &&
        !StreamSettingsService.current.gameAudioEnabled &&
        !StreamSettingsService.current.includeMicrophone) {
      throw StateError('Enable game audio or microphone in Streaming settings');
    }
    _state = StreamingLifecycleState.starting;
    _stateController.add(_state);
    try {
      final result = await _channel.invokeMethod<bool>('startStream', {
        'rtmpUrl': ingestUri,
        'width': width,
        'height': height,
        'bitrateKbps': bitrateKbps,
        'fps': fps,
        'audioMode': audioMode,
        'faceCamEnabled': faceCamEnabled,
        'faceCamCorner': faceCamCorner,
        'faceCamSize': faceCamSize,
      });
      if (result == true) {
        _state = StreamingLifecycleState.live;
        _stateController.add(_state);
      }
      return result ?? false;
    } on PlatformException catch (e) {
      _state = StreamingLifecycleState.error;
      _lastError = e.message;
      _stateController.add(_state);
      rethrow;
    }
  }

  static Future<void> stopStream() async {
    if (!StreamSettingsService.isSupported) return;
    await _channel.invokeMethod<void>('stopStream');
    _state = StreamingLifecycleState.idle;
    _lastError = null;
    _stateController.add(_state);
  }
}
