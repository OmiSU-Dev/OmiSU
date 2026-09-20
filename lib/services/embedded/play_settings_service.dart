import 'package:shared_preferences/shared_preferences.dart';

/// User preferences for built-in (embedded) libretro play.
class PlaySettings {
  const PlaySettings({
    this.autosaveOnExit = true,
    this.shaderFilter = 'auto',
    this.hdMode = false,
    this.hdModeQuality = 'medium',
    this.adaptiveHdMode = true,
    this.immersiveMode = false,
    this.rumbleEnabled = true,
    this.lowLatencyAudio = true,
    this.touchControlsEnabled = false,
    this.showFpsCounter = false,
  });

  final bool autosaveOnExit;
  final String shaderFilter;
  final bool hdMode;
  final String hdModeQuality;
  final bool adaptiveHdMode;
  final bool immersiveMode;
  final bool rumbleEnabled;
  final bool lowLatencyAudio;
  final bool touchControlsEnabled;
  final bool showFpsCounter;

  static const shaderFilters = ['auto', 'crt', 'lcd', 'smooth', 'sharp'];
  static const hdModeQualities = ['low', 'medium', 'high'];

  String get hdModeQualityLabel {
    switch (hdModeQuality) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      default:
        return 'Medium';
    }
  }

  PlaySettings copyWith({
    bool? autosaveOnExit,
    String? shaderFilter,
    bool? hdMode,
    String? hdModeQuality,
    bool? adaptiveHdMode,
    bool? immersiveMode,
    bool? rumbleEnabled,
    bool? lowLatencyAudio,
    bool? touchControlsEnabled,
    bool? showFpsCounter,
  }) {
    return PlaySettings(
      autosaveOnExit: autosaveOnExit ?? this.autosaveOnExit,
      shaderFilter: shaderFilter ?? this.shaderFilter,
      hdMode: hdMode ?? this.hdMode,
      hdModeQuality: hdModeQuality ?? this.hdModeQuality,
      adaptiveHdMode: adaptiveHdMode ?? this.adaptiveHdMode,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      rumbleEnabled: rumbleEnabled ?? this.rumbleEnabled,
      lowLatencyAudio: lowLatencyAudio ?? this.lowLatencyAudio,
      touchControlsEnabled: touchControlsEnabled ?? this.touchControlsEnabled,
      showFpsCounter: showFpsCounter ?? this.showFpsCounter,
    );
  }

  Map<String, dynamic> toEmbeddedParams() => {
        'autosaveOnExit': autosaveOnExit,
        'shaderFilter': shaderFilter,
        'hdMode': hdMode,
        'hdModeQuality': hdModeQuality,
        'adaptiveHdMode': adaptiveHdMode,
        'immersiveMode': immersiveMode,
        'rumbleEventsEnabled': rumbleEnabled,
        'preferLowLatencyAudio': lowLatencyAudio,
      };
}

class PlaySettingsService {
  PlaySettingsService._();

  static const _prefix = 'omisu_play_';
  static PlaySettings _cached = const PlaySettings();

  static PlaySettings get current => _cached;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = PlaySettings(
      autosaveOnExit: prefs.getBool('${_prefix}autosave') ?? true,
      shaderFilter: prefs.getString('${_prefix}shader') ?? 'auto',
      hdMode: prefs.getBool('${_prefix}hd') ?? false,
      hdModeQuality: _readHdModeQuality(prefs),
      adaptiveHdMode: prefs.getBool('${_prefix}adaptive_hd') ?? true,
      immersiveMode: prefs.getBool('${_prefix}immersive') ?? false,
      rumbleEnabled: prefs.getBool('${_prefix}rumble') ?? true,
      lowLatencyAudio: prefs.getBool('${_prefix}low_latency') ?? true,
      touchControlsEnabled: prefs.getBool('${_prefix}touch') ?? false,
      showFpsCounter: prefs.getBool('${_prefix}fps') ?? false,
    );
  }

  static Future<void> save(PlaySettings settings) async {
    _cached = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}autosave', settings.autosaveOnExit);
    await prefs.setString('${_prefix}shader', settings.shaderFilter);
    await prefs.setBool('${_prefix}hd', settings.hdMode);
    await prefs.setString('${_prefix}hd_quality', settings.hdModeQuality);
    await prefs.setBool('${_prefix}adaptive_hd', settings.adaptiveHdMode);
    await prefs.setBool('${_prefix}immersive', settings.immersiveMode);
    await prefs.setBool('${_prefix}rumble', settings.rumbleEnabled);
    await prefs.setBool('${_prefix}low_latency', settings.lowLatencyAudio);
    await prefs.setBool('${_prefix}touch', settings.touchControlsEnabled);
    await prefs.setBool('${_prefix}fps', settings.showFpsCounter);
  }

  static Future<void> update(PlaySettings Function(PlaySettings) fn) async {
    await save(fn(_cached));
  }

  /// Set when the user toggles touch controls in Settings or the pause menu.
  static Future<void> markTouchControlsUserConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}touch_user_set', true);
  }

  static Future<bool> isTouchControlsUserConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_prefix}touch_user_set') ?? false;
  }

  static String _readHdModeQuality(SharedPreferences prefs) {
    final stored = prefs.getString('${_prefix}hd_quality');
    if (stored != null && PlaySettings.hdModeQualities.contains(stored)) {
      return stored;
    }
    return 'medium';
  }
}
