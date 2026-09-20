import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:provider/provider.dart';

import '../../../../providers/sqlite_config_provider.dart';
import '../../../../widgets/custom_toggle_switch.dart';
import 'setting_row.dart';

/// Scan behaviour toggles shown at the top of the Library settings panel.
class LibraryScanSettingsSection extends StatelessWidget {
  static const int itemCount = 4;

  final bool isContentFocused;
  final int selectedContentIndex;
  final List<GlobalKey> itemKeys;
  final void Function(int localIndex) onItemSelected;

  const LibraryScanSettingsSection({
    super.key,
    required this.isContentFocused,
    required this.selectedContentIndex,
    required this.itemKeys,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = context.watch<SqliteConfigProvider>().config;
    var localIdx = 0;

    Widget buildToggle({
      required String titleKey,
      required String subtitleKey,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      final index = localIdx++;
      return Padding(
        padding: EdgeInsets.only(bottom: 12.r),
        child: SettingRow(
          key: itemKeys[index],
          onTap: () => onItemSelected(index),
          focused: isContentFocused && selectedContentIndex == index,
          title: titleKey.getString(context),
          subtitle: subtitleKey.getString(context),
          trailing: CustomToggleSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildToggle(
          titleKey: AppLocale.scanOnStartup,
          subtitleKey: AppLocale.scanOnStartupSubtitle,
          value: config.scanOnStartup,
          onChanged: (value) {
            context.read<SqliteConfigProvider>().updateScanOnStartup(value);
          },
        ),
        buildToggle(
          titleKey: AppLocale.ignoreHiddenFiles,
          subtitleKey: AppLocale.ignoreHiddenFilesSubtitle,
          value: config.ignoreHiddenFiles,
          onChanged: (value) {
            context.read<SqliteConfigProvider>().updateIgnoreHiddenFiles(value);
          },
        ),
        buildToggle(
          titleKey: AppLocale.autoScanOnChange,
          subtitleKey: AppLocale.autoScanOnChangeSubtitle,
          value: config.autoScanOnChange,
          onChanged: (value) {
            context.read<SqliteConfigProvider>().updateAutoScanOnChange(value);
          },
        ),
        buildToggle(
          titleKey: AppLocale.autoScanOnResume,
          subtitleKey: AppLocale.autoScanOnResumeSubtitle,
          value: config.autoScanOnResume,
          onChanged: (value) {
            context.read<SqliteConfigProvider>().updateAutoScanOnResume(value);
          },
        ),
      ],
    );
  }
}
