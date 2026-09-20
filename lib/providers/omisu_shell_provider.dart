import 'package:flutter/material.dart';

/// Y/A footer hints registered by the active tab (e.g. systems grid).
class OmisuFooterActions {
  const OmisuFooterActions({
    this.onSecondary,
    this.onPrimary,
    this.secondaryLabel,
    this.primaryLabel,
  });

  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final String? primaryLabel;
}

/// Shared shell state for the iiSU-style home chrome: focused item title,
/// optional stats subtitle, and blurred background art for the main grid.
class OmisuShellProvider extends ChangeNotifier {
  String? _focusTitle;
  String? _focusSubtitle;
  String? _focusAsciiLabel;
  String? _backgroundPath;
  bool _homeChromeActive = false;
  int _activeTabIndex = 0;
  OmisuFooterActions? _footerActions;

  String? get focusTitle => _focusTitle;
  String? get focusSubtitle => _focusSubtitle;
  String? get focusAsciiLabel => _focusAsciiLabel;
  String? get backgroundPath => _backgroundPath;
  bool get homeChromeActive => _homeChromeActive;
  int get activeTabIndex => _activeTabIndex;
  OmisuFooterActions? get footerActions => _footerActions;

  void setActiveTabIndex(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    notifyListeners();
  }

  void updateHomeFocus({
    required String title,
    String? subtitle,
    String? backgroundPath,
    String? asciiLabel,
  }) {
    _homeChromeActive = true;
    final changed =
        _focusTitle != title ||
        _focusSubtitle != subtitle ||
        _backgroundPath != backgroundPath ||
        _focusAsciiLabel != asciiLabel;
    _focusTitle = title;
    _focusSubtitle = subtitle;
    _backgroundPath = backgroundPath;
    _focusAsciiLabel = asciiLabel;
    if (changed) notifyListeners();
  }

  void setTabContext({required String title}) {
    _homeChromeActive = false;
    if (_focusTitle == title &&
        _focusSubtitle == null &&
        _backgroundPath == null &&
        _focusAsciiLabel == null &&
        !_homeChromeActive) {
      return;
    }
    _focusTitle = title;
    _focusSubtitle = null;
    _backgroundPath = null;
    _focusAsciiLabel = null;
    notifyListeners();
  }

  void clearFocus() {
    if (_focusTitle == null &&
        _focusSubtitle == null &&
        _backgroundPath == null &&
        _focusAsciiLabel == null &&
        !_homeChromeActive) {
      return;
    }
    _focusTitle = null;
    _focusSubtitle = null;
    _backgroundPath = null;
    _focusAsciiLabel = null;
    _homeChromeActive = false;
    notifyListeners();
  }

  void setFooterActions(OmisuFooterActions? actions) {
    final hadActions = _footerActions != null;
    final hasActions = actions != null;
    final labelsChanged =
        _footerActions?.secondaryLabel != actions?.secondaryLabel ||
        _footerActions?.primaryLabel != actions?.primaryLabel ||
        hadActions != hasActions;
    _footerActions = actions;
    if (labelsChanged) notifyListeners();
  }

  void clearFooterActions() => setFooterActions(null);
}
