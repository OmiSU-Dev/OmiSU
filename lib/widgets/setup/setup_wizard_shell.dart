import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/widgets/core_footer.dart';
import 'package:omisu/widgets/omisu/omisu_brand_mark.dart';
import 'package:omisu/widgets/omisu/omisu_glass_panel.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';
import 'package:omisu/widgets/omisu/omisu_shell_background.dart';
import 'package:omisu/widgets/omisu/omisu_status_title_pill.dart';
import 'package:omisu/widgets/setup/setup_wizard_progress.dart';

/// OmiSU shell chrome for first-run setup: top HUD + segment progress + glass
/// card + footer. Hybrid iiSU layout with Retro 82 / Omarchy theme tokens.
class SetupWizardShell extends StatelessWidget {
  const SetupWizardShell({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.stepTitle,
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.content,
    required this.footer,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final String stepTitle;
  final String welcomeTitle;
  final String welcomeSubtitle;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxContentWidth = isLandscape ? 560.w : 520.w;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: OmisuShellBackground()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.08),
                  Colors.transparent,
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.22),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.r, 8.r, 16.r, 4.r),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OmisuBrandMark(compact: true),
                      SizedBox(width: 12.r),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              welcomeTitle,
                              style: omisuRetroLabelStyle(
                                context,
                                size: isLandscape ? 12 : 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.r),
                            Text(
                              welcomeSubtitle,
                              style: omisuRetroLabelStyle(
                                context,
                                size: isLandscape ? 9 : 10,
                                weight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.62,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OmisuRetroPanel(
                        active: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.r,
                          vertical: 5.r,
                        ),
                        child: Text(
                          '${currentStep + 1}/$totalSteps',
                          style: omisuRetroLabelStyle(
                            context,
                            size: 10,
                            color: OmisuAccent.focusGradient[0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.r),
                Center(
                  child: OmisuStatusTitlePill(
                    title: stepTitle,
                    subtitle: 'STEP ${currentStep + 1}',
                    maxWidth: isLandscape ? 420 : 340,
                  ),
                ),
                SizedBox(height: 12.r),
                SetupWizardProgress(
                  currentStep: currentStep,
                  totalSteps: totalSteps,
                  stepLabels: stepLabels,
                ),
                SizedBox(height: 12.r),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.r),
                        child: OmisuGlassPanel(
                          gradientBorder: true,
                          cornerRadius: 6,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLandscape ? 20.r : 16.r,
                            vertical: isLandscape ? 16.r : 20.r,
                          ),
                          child: SingleChildScrollView(
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: kCoreFooterHeight.r,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.55),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.35),
                        width: 1.r,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.r),
                  alignment: Alignment.center,
                  child: footer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
