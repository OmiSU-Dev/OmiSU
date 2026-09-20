import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/providers/omisu_shell_provider.dart';
import 'package:omisu/widgets/core_footer.dart';
import 'package:omisu/widgets/omisu/omisu_nav_dock.dart';
import 'package:omisu/widgets/omisu/omisu_shell_layout.dart';
import 'package:provider/provider.dart';

/// iiSU-style bottom chrome: Y · nav dock · A in one row.
class OmisuShellFooter extends StatelessWidget {
  const OmisuShellFooter({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<OmisuShellProvider>(
      builder: (context, shell, _) {
        final actions = shell.footerActions;
        final showSecondary = actions?.onSecondary != null;
        final showPrimary = actions?.onPrimary != null;

        return Container(
          height: kOmisuShellFooterHeight.r,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.r),
          child: Row(
            children: [
              if (showSecondary) ...[
                GamepadControl(
                  role: GamepadControlRole.secondary,
                  label:
                      actions!.secondaryLabel ??
                      AppLocale.hintOptions.getString(context),
                  iconPath: 'assets/images/gamepad/Xbox_Y_button.png',
                  onTap: actions.onSecondary,
                ),
                SizedBox(width: 8.r),
              ],
              Expanded(
                child: OmisuNavDock(
                  selectedTabIndex: selectedTabIndex,
                  onTabSelected: onTabSelected,
                  compact: true,
                ),
              ),
              if (showPrimary) ...[
                SizedBox(width: 8.r),
                GamepadControl(
                  role: GamepadControlRole.primary,
                  label:
                      actions!.primaryLabel ??
                      AppLocale.enter.getString(context),
                  iconPath: 'assets/images/gamepad/Xbox_A_button.png',
                  onTap: actions.onPrimary,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
