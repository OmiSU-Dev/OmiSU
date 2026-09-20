import 'nordi_config.dart';

/// Which OTA sources are active on Nordi curated builds.
///
/// **App APK:** [NordiConfig.githubReleasesRepo] when [appGithubOtaEnabled], or
/// Wi‑Fi deploy from the monorepo. NeoStation APK OTA stays off on Nordi unless
/// [NordiConfig.useNeostationGithubOta].
///
/// **Built-in player:** optional upstream cores/engine (not NeoStation).
class NordiUpdatePolicy {
  NordiUpdatePolicy._();

  /// Launcher APK from GitHub Releases (OmiSU-Dev/OmiSU or NeoStation upstream).
  static bool get appGithubOtaEnabled {
    if (!NordiConfig.curatedBuild) return true;
    return NordiConfig.enableGithubAppOta ||
        NordiConfig.useNeostationGithubOta;
  }

  /// Remote `assets/systems` manifest from NeoStation — off on curated Nordi.
  static bool get systemsJsonGithubOtaEnabled =>
      !NordiConfig.curatedBuild || NordiConfig.useNeostationGithubOta;

  @Deprecated('Use systemsJsonGithubOtaEnabled or appGithubOtaEnabled')
  static bool get neostationGithubOtaEnabled => systemsJsonGithubOtaEnabled;

  static bool get builtinPlayerOtaEnabled => true;

  /// Human-facing hint for settings / support docs.
  static String get appUpdateChannelDescription {
    if (NordiConfig.curatedBuild && NordiConfig.enableGithubAppOta) {
      return 'Nordi app updates: GitHub ${NordiConfig.githubReleasesRepo} '
          '(or scripts/deploy-nordi-wifi.sh from monorepo)';
    }
    return 'Nordi app updates: build on PC and run scripts/deploy-nordi-wifi.sh';
  }
}
