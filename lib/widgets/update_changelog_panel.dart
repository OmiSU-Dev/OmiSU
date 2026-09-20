import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:omisu/l10n/app_locale.dart';
import 'package:omisu/utils/release_notes_display.dart';

/// Scrollable release notes shown before the user accepts an OTA update.
class UpdateChangelogPanel extends StatelessWidget {
  final String? releaseNotes;
  final double maxHeight;

  const UpdateChangelogPanel({
    super.key,
    required this.releaseNotes,
    this.maxHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = ReleaseNotesDisplay.formatForDisplay(releaseNotes);
    final hasNotes = formatted.isNotEmpty;
    final showWarning =
        hasNotes && ReleaseNotesDisplay.mentionsKnownIssues(releaseNotes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.updateReleaseNotesTitle.getString(context),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6.r),
        if (showWarning) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.warning_rounded,
                  size: 14.r,
                  color: theme.colorScheme.error,
                ),
                SizedBox(width: 6.r),
                Expanded(
                  child: Text(
                    AppLocale.updateKnownIssueWarning.getString(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.r),
        ],
        Container(
          constraints: BoxConstraints(maxHeight: maxHeight.r),
          width: double.infinity,
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              hasNotes
                  ? formatted
                  : AppLocale.updateNoReleaseNotes.getString(context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: hasNotes ? 0.85 : 0.55,
                ),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
