import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'settings_title.dart';

class NordiPowerSettingsContent extends StatefulWidget {
  const NordiPowerSettingsContent({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
  });

  final bool isContentFocused;
  final int selectedContentIndex;

  @override
  State<NordiPowerSettingsContent> createState() =>
      NordiPowerSettingsContentState();
}

class NordiPowerSettingsContentState extends State<NordiPowerSettingsContent> {
  static const _channel = MethodChannel('com.omisu.launcher/launcher');

  int getItemCount() => 3;

  Future<void> _reboot() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('rebootDevice');
  }

  Future<void> _shutdown() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('shutdownDevice');
  }

  void selectItem(int index) {
    switch (index) {
      case 0:
        _reboot();
      case 1:
        _shutdown();
      case 2:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsTitle(
          title: 'Restart / Reboot',
          subtitle: 'Restart or shut down the device',
        ),
        SizedBox(height: 12.r),
        _row(
          theme,
          index: 0,
          icon: Symbols.restart_alt_rounded,
          label: 'Restart device',
        ),
        SizedBox(height: 8.r),
        _row(
          theme,
          index: 1,
          icon: Symbols.power_settings_new_rounded,
          label: 'Shut down device',
        ),
        SizedBox(height: 8.r),
        _row(
          theme,
          index: 2,
          icon: Symbols.close_rounded,
          label: 'Cancel',
          muted: true,
        ),
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
