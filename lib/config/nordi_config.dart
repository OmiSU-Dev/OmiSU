/// Nordi — curated Nord N30 build (this repo copy always enabled).
class NordiConfig {
  NordiConfig._();

  static const bool curatedBuild = true;

  static const String deviceTarget = 'nord_n30';
  static const String partner = 'gamesir';

  /// Fixed library root on the preload image (`OMISU_OEM_ROM_ROOT` alias).
  static const String defaultRomRoot = String.fromEnvironment(
    'NORDI_ROM_ROOT',
    defaultValue: String.fromEnvironment(
      'OMISU_OEM_ROM_ROOT',
      defaultValue: '/storage/emulated/0/ROMS',
    ),
  );

  static const String defaultSystemArtThemeFolder = 'NeoStation';

  static const String prefsBootstrapDone = 'nordi_bootstrap_done_v1';

  /// Ensures default [defaultRomRoot] is registered (e.g. after path change to ROMS).
  static const String prefsDefaultRomFolderEnsured = 'nordi_default_rom_ensured_v2';

  /// Nordi is a separate product from NeoStation. Never install APKs or pull
  /// system JSON from `misobadev/neostation-frontend` on device.
  ///
  /// **Ship app changes:** `./scripts/deploy-nordi-wifi.sh` from the monorepo.
  /// **Port upstream code:** merge/cherry-pick in git, then deploy — see
  /// `docs/nordi-update-channel.md`.
  static const bool useNeostationGithubOta = false;

  /// GitHub Releases source for Nordi APK OTA (`owner/repo`).
  static const String githubReleasesRepo = 'OmiSU-Dev/OmiSU';

  /// When true, [UpdateService] polls [githubReleasesRepo] on curated builds.
  static const bool enableGithubAppOta = true;
}
