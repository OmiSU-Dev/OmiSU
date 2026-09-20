import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/nordi/nordi_safe_mode_service.dart';

class NordiSettings {
  NordiSettings._();

  /// Retail handheld UX (hidden Exit, power menu, no launcher picker).
  static bool get handheldRetailUi =>
      NordiConfig.curatedBuild && !NordiSafeModeService.isEnabled;

  static const hiddenMenuLocaleKeys = {
    AppLocale.tools,
    AppLocale.exit,
  };

  static const powerMenuLocaleKey = 'nordi_power_menu';

  static bool isMenuHidden(String localeKey) {
    if (!handheldRetailUi) return false;
    return hiddenMenuLocaleKeys.contains(localeKey);
  }
}
