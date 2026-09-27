import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/nordi/nordi_settings.dart';

import 'settings_title.dart';

class NordiPowerSettingsContent extends StatefulWidget {
  const NordiPowerSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
    this.onExitApp,
  });

  final bool isContentFocused;
  final int selectedContentIndex;
  final VoidCallback? onExitApp;

  @override
  State<NordiPowerSettingsContent> createState() =>
      NordiPowerSettingsContentState();
}

class NordiPowerSettingsContentState extends State<NordiPowerSettingsContent> {
  static const _channel = MethodChannel('com.omisu.launcher/launcher');

  bool get _showExitApp => !NordiSettings.handheldRetailUi;

  int getItemCount() => (_showExitApp ? 1 : 0) + 4;

  Future<void> _restartLauncher() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('restartLauncher');
  }

  Future<void> _reboot() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('rebootDevice');
  }

  Future<void> _shutdown() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('shutdownDevice');
  }

  void selectItem(int index) {
    final cancelIndex = getItemCount() - 1;
    if (index == cancelIndex) return;

    if (index == 0) {
      _restartLauncher();
      return;
    }
    if (index == 1) {
      _reboot();
      return;
    }
    if (index == 2) {
      _shutdown();
      return;
    }
    if (_showExitApp && index == 3) {
      widget.onExitApp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[
      _row(
        theme,
        index: 0,
        icon: Symbols.refresh_rounded,
        label: AppLocale.nordiPowerRestartLauncher.getString(context),
      ),
      SizedBox(height: 8.r),
      _row(
        theme,
        index: 1,
        icon: Symbols.restart_alt_rounded,
        label: AppLocale.nordiPowerRestartDevice.getString(context),
      ),
      SizedBox(height: 8.r),
      _row(
        theme,
        index: 2,
        icon: Symbols.power_settings_new_rounded,
        label: AppLocale.nordiPowerShutdownDevice.getString(context),
      ),
    ];

    if (_showExitApp) {
      rows.add(SizedBox(height: 8.r));
      rows.add(
        _row(
          theme,
          index: 3,
          icon: Symbols.exit_to_app_rounded,
          label: AppLocale.exitApplication.getString(context),
        ),
      );
    }

    rows.add(SizedBox(height: 8.r));
    rows.add(
      _row(
        theme,
        index: getItemCount() - 1,
        icon: Symbols.close_rounded,
        label: AppLocale.cancel.getString(context),
        muted: true,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsTitle(
          title: AppLocale.nordiPowerMenu.getString(context),
          subtitle: AppLocale.nordiPowerMenuSubtitle.getString(context),
        ),
        SizedBox(height: 12.r),
        ...rows,
      ],
    );
  }

  Widget _row(
    ThemeData theme, {
    required int index,
    required IconData icon,
    required String label,
    bool muted = false,
  }) {
    final focused =
        widget.isContentFocused && widget.selectedContentIndex == index;
    return Material(
      color: focused
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: muted ? theme.disabledColor : null),
        title: Text(label),
        onTap: () => selectItem(index),
      ),
    );
  }
}
