import '../launch/device_profile.dart';
import '../launch/device_profile_service.dart';

/// Maps stored quality preset (including [auto]) to encoder targets.
class StreamQualityResolver {
  StreamQualityResolver._();

  static const fixedPresets = ['540p', '720p', '1080p'];

  /// Effective preset used for width / height (never [auto]).
  ///
  /// [auto] caps at 720p and defaults to 540p so phone uplink stays stable on
  /// Kick/Twitch (avoids "unstable connection" at 1080p/high bitrate).
  static String effectivePreset(String stored) {
    if (stored != 'auto') {
      return fixedPresets.contains(stored) ? stored : '720p';
    }
    final profile = DeviceProfileService.instance.profile;
    final ram = profile.ramGb ?? 4;
    if (profile.tier == DevicePerformanceTier.high && ram >= 8) {
      return '720p';
    }
    return '540p';
  }

  static int widthFor(String stored) => switch (effectivePreset(stored)) {
        '1080p' => 1920,
        '540p' => 960,
        _ => 1280,
      };

  static int heightFor(String stored) => switch (effectivePreset(stored)) {
        '1080p' => 1080,
        '540p' => 540,
        _ => 720,
      };

  /// Target video bitrate (kbps). Auto uses fixed Kick-friendly caps, not pixel scaling.
  static int bitrateKbpsFor(String stored) {
    if (stored != 'auto') {
      return switch (effectivePreset(stored)) {
        '1080p' => 3500,
        '720p' => 1800,
        _ => 1200,
      };
    }
    return switch (effectivePreset('auto')) {
      '720p' => 1800,
      _ => 1200,
    };
  }

  /// Estimated live range (StreamPack regulator). External play uses a tighter floor.
  static ({int min, int max}) variableBitrateRangeKbps(
    String stored, {
    bool externalPlay = false,
  }) {
    final max = bitrateKbpsFor(stored);
    final floorFactor = externalPlay ? 0.28 : 0.30;
    final min = (max * floorFactor).round().clamp(450, max);
    return (min: min, max: max);
  }

  static int fpsFor(String stored) {
    if (stored == 'auto') return 30;
    final preset = effectivePreset(stored);
    return preset == '1080p' ? 30 : 24;
  }
}
