import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/services/sfx_service.dart';
import 'package:omisu/widgets/core_footer.dart';
import 'package:omisu/widgets/omisu/omisu_shell_layout.dart';

/// Bottom strip with a tappable **B Back** control for pushed routes that cover
/// the app shell footer (e.g. the collections browser).
class OmisuBackFooterBar extends StatelessWidget {
  const OmisuBackFooterBar({
    super.key,
    required this.onBack,
    this.label,
  });

  final VoidCallback onBack;
  final String? label;

  void _handleBack() {
    SfxService().playBackSound();
    onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kOmisuShellFooterHeight.r,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.r),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GamepadControl(
          role: GamepadControlRole.secondary,
          label: label ?? AppLocale.hintBack.getString(context),
          iconPath: 'assets/images/gamepad/Xbox_B_button.png',
          onTap: _handleBack,
        ),
      ),
    );
  }
}
