import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:omisu/services/launch/device_profile.dart';
import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/services/nordi/nordi_settings.dart';
import 'package:omisu/services/logger_service.dart';

/// Detects the host device once and exposes a [DeviceProfile] for launch tuning.
class DeviceProfileService {
  DeviceProfileService._();

  static final DeviceProfileService instance = DeviceProfileService._();

  static final _log = LoggerService.instance;

  DeviceProfile? _profile;
  DeviceProfile? _simulatedProfile;

  DeviceProfile get profile =>
      _simulatedProfile ?? _profile ?? DeviceProfileService.fallback;

  /// Override detection (debug / `flutter run --dart-define=OMISU_DEVICE_PROFILE=nord_n30`).
  void simulateProfile(DeviceProfile? profile) {
    _simulatedProfile = profile;
    _log.i(
      '[LaunchTune] Device simulation: ${profile == null ? "off (auto)" : profile}',
    );
  }

  /// Built-in profiles for QA on desktop builds.
  static const DeviceProfile nordN30 = DeviceProfile(
    id: 'nord_n30',
    model: 'CPH2583 (simulated)',
    manufacturer: 'OnePlus',
    ramGb: 8,
    tier: DevicePerformanceTier.mid,
    isKnownTarget: true,
  );

  static const DeviceProfile androidLow = DeviceProfile(
    id: 'android_low',
    model: 'Simulated low-end',
    manufacturer: 'Android',
    ramGb: 3,
    tier: DevicePerformanceTier.low,
  );

  static const DeviceProfile androidMid = DeviceProfile(
    id: 'android_mid',
    model: 'Simulated mid-range',
    manufacturer: 'Android',
    ramGb: 6,
    tier: DevicePerformanceTier.mid,
  );

  /// Call during startup before the first game launch.
  Future<DeviceProfile> initialize() async {
    if (_profile != null) return profile;

    const simulatedId = String.fromEnvironment('OMISU_DEVICE_PROFILE');
    if (simulatedId.isNotEmpty) {
      _simulatedProfile = profileFromId(simulatedId);
      _log.i('[LaunchTune] Device profile (dart-define): $_simulatedProfile');
    }

    if (Platform.isAndroid) {
      _profile = await _detectAndroid();
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      _profile = await _detectDesktop();
    } else {
      _profile = fallback;
    }

    _log.i('[LaunchTune] Device profile: $profile');
    return profile;
  }

  static DeviceProfile? profileFromId(String id) {
    switch (id.toLowerCase()) {
      case 'nord_n30':
      case 'nord-n30':
        return nordN30;
      case 'android_low':
      case 'low':
        return androidLow;
      case 'android_mid':
      case 'mid':
        return androidMid;
      default:
        return null;
    }
  }

  static const DeviceProfile fallback = DeviceProfile(
    id: 'generic',
    model: 'unknown',
    manufacturer: 'unknown',
    ramGb: null,
    tier: DevicePerformanceTier.mid,
  );

  Future<DeviceProfile> _detectAndroid() async {
    if (NordiSettings.handheldRetailUi) {
      final info = await DeviceInfoPlugin().androidInfo;
      return DeviceProfile(
        id: NordiConfig.deviceTarget,
        model: info.model.trim(),
        manufacturer: info.manufacturer.trim(),
        ramGb: info.physicalRamSize > 0 ? info.physicalRamSize ~/ 1024 : 8,
        tier: DevicePerformanceTier.mid,
        isKnownTarget: true,
      );
    }

    final info = await DeviceInfoPlugin().androidInfo;
    final model = info.model.trim();
    final manufacturer = info.manufacturer.trim();
    final ramGb = info.physicalRamSize > 0 ? info.physicalRamSize ~/ 1024 : null;
    final modelLower = model.toLowerCase();
    final brandLower = '${info.brand} ${info.device}'.toLowerCase();

    // OnePlus Nord N30 / CPH2583 family — primary OmiSU handheld target.
    final isNordN30 = modelLower.contains('nord n30') ||
        modelLower.contains('cph258') ||
        brandLower.contains('nord n30');

    if (isNordN30) {
      return DeviceProfile(
        id: 'nord_n30',
        model: model,
        manufacturer: manufacturer,
        ramGb: ramGb ?? 8,
        tier: DevicePerformanceTier.mid,
        isKnownTarget: true,
      );
    }

    return DeviceProfile(
      id: 'android_${_tierSlug(_tierFromRam(ramGb))}',
      model: model,
      manufacturer: manufacturer,
      ramGb: ramGb,
      tier: _tierFromRam(ramGb),
    );
  }

  Future<DeviceProfile> _detectDesktop() async {
    int? ramGb;
    try {
      if (Platform.isLinux) {
        final meminfo = File('/proc/meminfo');
        if (meminfo.existsSync()) {
          for (final line in meminfo.readAsLinesSync()) {
            if (!line.startsWith('MemTotal:')) continue;
            final kb = int.tryParse(
              RegExp(r'(\d+)').firstMatch(line)?.group(1) ?? '',
            );
            ramGb = kb == null ? null : kb ~/ (1024 * 1024);
            break;
          }
        }
      } else if (Platform.isWindows) {
        final info = await DeviceInfoPlugin().windowsInfo;
        ramGb = info.systemMemoryInMegabytes ~/ 1024;
      } else if (Platform.isMacOS) {
        final info = await DeviceInfoPlugin().macOsInfo;
        ramGb = info.memorySize ~/ (1024 * 1024 * 1024);
      }
    } catch (_) {}

    final tier = _tierFromRam(ramGb);
    return DeviceProfile(
      id: 'desktop_${_tierSlug(tier)}',
      model: Platform.operatingSystem,
      manufacturer: 'desktop',
      ramGb: ramGb,
      tier: tier,
    );
  }

  static DevicePerformanceTier _tierFromRam(int? ramGb) {
    if (ramGb == null) return DevicePerformanceTier.mid;
    if (ramGb <= 4) return DevicePerformanceTier.low;
    if (ramGb <= 8) return DevicePerformanceTier.mid;
    return DevicePerformanceTier.high;
  }

  static String _tierSlug(DevicePerformanceTier tier) => switch (tier) {
        DevicePerformanceTier.low => 'low',
        DevicePerformanceTier.mid => 'mid',
        DevicePerformanceTier.high => 'high',
      };
}
