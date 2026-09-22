/// How [DeviceProfileService.profile] was chosen.
enum DeviceProfileSource {
  detected,
  dartDefine,
  debugSimulate,
}

/// Hardware tier used to pick launch-time emulator tuning.
enum DevicePerformanceTier {
  /// ≤4 GB RAM or very slow SoC class.
  low,

  /// Typical mid-range phone (e.g. Snapdragon 6-series, 6–8 GB RAM).
  mid,

  /// Flagship / desktop class.
  high,
}

/// Snapshot of the host device captured once at startup.
class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.model,
    required this.manufacturer,
    required this.ramGb,
    required this.tier,
    this.isKnownTarget = false,
  });

  /// Stable slug for bundled tuning tables (`nord_n30`, `generic_android_mid`, …).
  final String id;

  final String model;
  final String manufacturer;
  final int? ramGb;
  final DevicePerformanceTier tier;

  /// True when we matched a curated profile (Nord N30 build target, etc.).
  final bool isKnownTarget;

  /// Human-readable line for Settings → Playback (not internal [id]).
  String get playbackAutoTuneLabel {
    final ram = ramGb != null ? '${ramGb} GB RAM' : 'RAM unknown';
    final tierLabel = switch (tier) {
      DevicePerformanceTier.low => 'Low',
      DevicePerformanceTier.mid => 'Mid',
      DevicePerformanceTier.high => 'High',
    };
    if (isKnownTarget) {
      return 'OnePlus Nord N30 · $ram · $tierLabel tier';
    }
    final prefix =
        manufacturer.isNotEmpty ? '${manufacturer.trim()} ' : '';
    return '${prefix}${model.trim()} · $ram · $tierLabel tier';
  }

  @override
  String toString() =>
      'DeviceProfile(id=$id, model=$model, ram=${ramGb ?? "?"}GB, tier=$tier)';
}
