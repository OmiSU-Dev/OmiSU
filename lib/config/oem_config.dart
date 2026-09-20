import 'nordi_config.dart';

/// Plan-aligned OEM gate for the Nordi curated tree (`gamesir` / Nord N30).
///
/// Universal OmiSU lives in `neostation-frontend-main`; this file maps the
/// same conceptual flags to [NordiConfig] so OEM branches read one API.
class OemConfig {
  OemConfig._();

  static const bool kPreloadedOem = NordiConfig.curatedBuild;

  static const String kOemDevice = NordiConfig.deviceTarget;

  static const String kOemPartner = NordiConfig.partner;

  static const String kOemRomRoot = NordiConfig.defaultRomRoot;

  static bool get isGamesirHandheld =>
      kPreloadedOem && kOemPartner == 'gamesir';
}
