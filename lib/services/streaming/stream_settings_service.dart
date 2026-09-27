import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'stream_quality_resolver.dart';

/// Global RTMP streaming preferences (Android).
class StreamSettings {
  const StreamSettings({
    this.rtmpServerUrl = '',
    this.streamKey = '',
    this.qualityPreset = 'auto',
    this.gameAudioEnabled = true,
    this.includeMicrophone = false,
    this.faceCamEnabled = false,
    this.faceCamCorner = 'bottomRight',
    this.faceCamSize = 'medium',
  });

  final String rtmpServerUrl;
  final String streamKey;
  final String qualityPreset;
  final bool gameAudioEnabled;
  final bool includeMicrophone;
  final bool faceCamEnabled;
  final String faceCamCorner;
  final String faceCamSize;

  bool get isConfigured =>
      rtmpServerUrl.trim().isNotEmpty && streamKey.trim().isNotEmpty;

  /// Full ingest URI for StreamPack (server + key).
  String get ingestUri {
    final base = rtmpServerUrl.trim();
    final key = streamKey.trim();
    if (base.isEmpty || key.isEmpty) return '';
    final normalized = base.endsWith('/') ? base : '$base/';
    try {
      return Uri.parse(normalized).resolve(key).toString();
    } catch (_) {
      return '$normalized$key';
    }
  }

  String get effectiveQualityPreset =>
      StreamQualityResolver.effectivePreset(qualityPreset);

  int get width => StreamQualityResolver.widthFor(qualityPreset);

  int get height => StreamQualityResolver.heightFor(qualityPreset);

  int get bitrateKbps => StreamQualityResolver.bitrateKbpsFor(qualityPreset);

  int get fps => StreamQualityResolver.fpsFor(qualityPreset);

  /// Wire value for Android [StreamAudioMode].
  String get audioMode {
    if (includeMicrophone && gameAudioEnabled) return 'mixed';
    if (includeMicrophone) return 'mic';
    return 'game';
  }

  StreamSettings copyWith({
    String? rtmpServerUrl,
    String? streamKey,
    String? qualityPreset,
    bool? gameAudioEnabled,
    bool? includeMicrophone,
    bool? faceCamEnabled,
    String? faceCamCorner,
    String? faceCamSize,
  }) {
    return StreamSettings(
      rtmpServerUrl: rtmpServerUrl ?? this.rtmpServerUrl,
      streamKey: streamKey ?? this.streamKey,
      qualityPreset: qualityPreset ?? this.qualityPreset,
      gameAudioEnabled: gameAudioEnabled ?? this.gameAudioEnabled,
      includeMicrophone: includeMicrophone ?? this.includeMicrophone,
      faceCamEnabled: faceCamEnabled ?? this.faceCamEnabled,
      faceCamCorner: faceCamCorner ?? this.faceCamCorner,
      faceCamSize: faceCamSize ?? this.faceCamSize,
    );
  }

  static const twitchServer = 'rtmps://live.twitch.tv/app/';
  static const youtubeServer = 'rtmps://a.rtmp.youtube.com/live2/';
  /// Documented Kick custom RTMP endpoint; confirm in Creator Dashboard if ingest fails.
  static const kickServer =
      'rtmps://fa723fc1b171.global-contribute.live-video.net/app/';
  static const qualityPresets = ['auto', '540p', '720p', '1080p'];
  static const faceCamCorners = ['bottomRight', 'bottomLeft', 'topRight', 'topLeft'];
  static const faceCamSizes = ['small', 'medium', 'large'];
}

class StreamSettingsService {
  StreamSettingsService._();

  static const _prefix = 'omisu_stream_';
  static const _perGamePrefix = 'omisu_stream_game_';

  static StreamSettings _cached = const StreamSettings();

  static StreamSettings get current => _cached;

  static bool get isSupported => Platform.isAndroid;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = StreamSettings(
      rtmpServerUrl: prefs.getString('${_prefix}server') ?? '',
      streamKey: prefs.getString('${_prefix}key') ?? '',
      qualityPreset: _readQuality(prefs),
      gameAudioEnabled: prefs.getBool('${_prefix}game_audio') ?? true,
      includeMicrophone: prefs.getBool('${_prefix}include_mic') ?? false,
      faceCamEnabled: prefs.getBool('${_prefix}face_cam') ?? false,
      faceCamCorner: prefs.getString('${_prefix}face_corner') ?? 'bottomRight',
      faceCamSize: prefs.getString('${_prefix}face_size') ?? 'medium',
    );
  }

  static Future<StreamSettings> ensureStreamCredentials() async {
    await load();
    return _cached;
  }

  static Future<void> save(StreamSettings settings) async {
    _cached = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}server', settings.rtmpServerUrl);
    await prefs.setString('${_prefix}key', settings.streamKey);
    await prefs.setString('${_prefix}quality', settings.qualityPreset);
    await prefs.setBool('${_prefix}game_audio', settings.gameAudioEnabled);
    await prefs.setBool('${_prefix}include_mic', settings.includeMicrophone);
    await prefs.setBool('${_prefix}face_cam', settings.faceCamEnabled);
    await prefs.setString('${_prefix}face_corner', settings.faceCamCorner);
    await prefs.setString('${_prefix}face_size', settings.faceCamSize);
  }

  static Future<void> update(StreamSettings Function(StreamSettings) fn) async {
    await save(fn(_cached));
  }

  static Future<bool> getStreamOnLaunch(String romPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_perGamePrefix$romPath') ?? false;
  }

  static Future<void> setStreamOnLaunch(String romPath, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_perGamePrefix$romPath', enabled);
  }

  static String _readQuality(SharedPreferences prefs) {
    final stored = prefs.getString('${_prefix}quality');
    if (stored != null && StreamSettings.qualityPresets.contains(stored)) {
      return stored;
    }
    return 'auto';
  }

  /// Validates RTMP URL shape without connecting.
  static String? validateServerUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'Server URL is required';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return 'Enter a valid RTMP or RTMPS URL';
    }
    if (uri.scheme != 'rtmp' && uri.scheme != 'rtmps') {
      return 'URL must start with rtmp:// or rtmps://';
    }
    return null;
  }
}
