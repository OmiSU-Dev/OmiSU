export '../nordi/nordi_bootstrap_service.dart';

import 'package:omisu/providers/neo_assets_provider.dart';
import 'package:omisu/providers/sqlite_config_provider.dart';
import 'package:omisu/services/nordi/nordi_bootstrap_service.dart';

/// Plan-aligned entry point for curated OEM bootstrap.
class OemBootstrapService {
  OemBootstrapService._();

  static Future<void> applyIfNeeded({
    required SqliteConfigProvider configProvider,
  }) =>
      NordiBootstrapService.applyIfNeeded(configProvider: configProvider);

  static Future<void> ensureDefaultSystemArt({
    required SqliteConfigProvider configProvider,
    required NeoAssetsProvider neoAssets,
  }) =>
      NordiBootstrapService.ensureDefaultSystemArt(
        configProvider: configProvider,
        neoAssets: neoAssets,
      );

  static Future<void> ensureDefaultRomFolder({
    required SqliteConfigProvider configProvider,
  }) =>
      NordiBootstrapService.ensureDefaultRomFolder(
        configProvider: configProvider,
      );
}
