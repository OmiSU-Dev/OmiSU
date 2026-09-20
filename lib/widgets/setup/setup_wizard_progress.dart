import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Horizontal segment rail for the setup wizard — iiSU-style synthwave underline,
/// not NeoStation's numbered vertical circles.
class SetupWizardProgress extends StatelessWidget {
  const SetupWizardProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    assert(stepLabels.length == totalSteps);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              final isActive = isCompleted || isCurrent;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 4.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.r),
                          gradient: isActive
                              ? OmisuAccent.focusRingGradient
                              : null,
                          color: isActive
                              ? null
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.22,
                                ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 6.r,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      SizedBox(height: 6.r),
                      Text(
                        stepLabels[index].toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: omisuRetroLabelStyle(
                          context,
                          size: 7,
                          letterSpacing: 0.4,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : isCompleted
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                )
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.35,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
