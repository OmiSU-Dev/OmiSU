import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Reusable settings title component with title and subtitle
class SettingsTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SettingsTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: omisuRetroLabelStyle(
            context,
            size: 13,
            weight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 6.r),
          Text(
            subtitle!,
            style: omisuRetroLabelStyle(
              context,
              size: 9,
              weight: FontWeight.w500,
              letterSpacing: 0.15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ],
    );
  }
}
