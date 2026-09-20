import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/widgets/omisu/omisu_tab_strip.dart';

/// iiSU-style nav dock — tab strip in the bottom footer (or standalone).
class OmisuNavDock extends StatelessWidget {
  const OmisuNavDock({
    super.key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    this.compact = false,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = compact ? kOmisuNavDockCompactHeight : kOmisuNavDockHeight;
        return SizedBox(
          height: height.r,
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              child: OmisuTabStrip(
                selectedTabIndex: selectedTabIndex,
                onTabSelected: onTabSelected,
                maxWidth: constraints.maxWidth,
                showBumpers: false,
                compact: compact,
              ),
            ),
          ),
        );
      },
    );
  }
}
