import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';
import 'package:omisu/widgets/omisu/omisu_retro_chrome.dart';

/// Terminal-style title readout under the header tab strip.
class OmisuStatusTitlePill extends StatelessWidget {
  const OmisuStatusTitlePill({
    super.key,
    required this.title,
    this.subtitle,
    this.maxWidth = 320,
  });

  final String title;
  final String? subtitle;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth.r),
      child: OmisuRetroPanel(
        active: true,
        cornerRadius: 3,
        padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 4.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '>',
              style: omisuRetroLabelStyle(
                context,
                size: 10,
                color: OmisuAccent.focusGradient[0],
              ),
            ),
            SizedBox(width: 6.r),
            Flexible(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: omisuRetroLabelStyle(context, size: 10, letterSpacing: 0.7),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(width: 8.r),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: OmisuAccent.focusGradient[2].withValues(alpha: 0.45),
                    width: 1.r,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.55),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.r, vertical: 1.r),
                  child: Text(
                    subtitle!.toUpperCase(),
                    style: omisuRetroLabelStyle(
                      context,
                      size: 8,
                      color: OmisuAccent.focusGradient[2],
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
