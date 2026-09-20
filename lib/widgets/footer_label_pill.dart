import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/omisu_accent.dart';
import 'omisu/omisu_retro_chrome.dart';

/// Left-hand label of a split-layout [CoreFooter]: HUD readout for the focused item.
class FooterLabelPill extends StatelessWidget {
  final String label;
  final String? countText;

  const FooterLabelPill({super.key, required this.label, this.countText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: OmisuRetroPanel(
        cornerRadius: 3,
        padding: EdgeInsets.symmetric(
          horizontal: 10.r,
          vertical: 4.r,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '>',
              style: omisuRetroLabelStyle(
                context,
                size: 9,
                color: OmisuAccent.focusGradient[0],
              ),
            ),
            SizedBox(width: 6.r),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: omisuRetroLabelStyle(
                  context,
                  size: 10,
                  letterSpacing: 0.65,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (countText != null) ...[
              SizedBox(width: 8.r),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: OmisuAccent.focusGradient[2].withValues(alpha: 0.4),
                    width: 1.r,
                  ),
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.r, vertical: 1.r),
                  child: Text(
                    countText!.toUpperCase(),
                    style: omisuRetroLabelStyle(
                      context,
                      size: 8,
                      color: OmisuAccent.focusGradient[2],
                      letterSpacing: 0.5,
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
