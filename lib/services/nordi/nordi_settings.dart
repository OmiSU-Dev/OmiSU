import 'package:omisu/config/nordi_config.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/nordi/nordi_safe_mode_service.dart';

class NordiSettings {
  NordiSettings._();

  /// Retail handheld UX (hidden Exit/Tools in menu; Power Menu always on Nordi).
  static bool get handheldRetailUi =>
      NordiConfig.curatedBuild && !NordiSafeModeService.isEnabled;

  static const hiddenMenuLocaleKeys = {
    AppLocale.tools,
    AppLocale.exit,
  };

  static const powerMenuLocaleKey = AppLocale.nordiPowerMenu;

  static bool isMenuHidden(String localeKey) {
    if (!NordiConfig.curatedBuild) return false;
    // Exit lives under Power Menu (Safe mode adds "Exit application" there).
    if (localeKey == AppLocale.exit) return true;
    if (handheldRetailUi && localeKey == AppLocale.tools) return true;
    return false;
  }
}
