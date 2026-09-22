import 'package:omisu/config/nordi_config.dart';

/// User-visible path strings (settings, pickers, dialogs). Storage paths on
/// disk may still contain legacy `NeoStation` segments until the user moves data.
class AppPathDisplay {
  AppPathDisplay._();

  static const String _legacyPublicFolder = 'NeoStation';

  /// Formats [raw] for display in the UI (never use for filesystem I/O).
  static String forUser(String raw) {
    if (raw.isEmpty || !raw.contains(_legacyPublicFolder)) {
      return raw;
    }
    return raw.replaceAll(_legacyPublicFolder, NordiConfig.productDisplayName);
  }
}
