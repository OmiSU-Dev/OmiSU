import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// Omarchy-style HUD panel: near-sharp corners, 1px sage rim, charcoal fill.
class OmisuRetroPanel extends StatelessWidget {
  const OmisuRetroPanel({
    super.key,
    required this.child,
    this.padding,
    this.active = false,
    this.cornerRadius = 2,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool active;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outerRadius = cornerRadius.r;
    final innerRadius = (cornerRadius - 1).clamp(0, cornerRadius).r;

    final rim = active
        ? OmisuAccent.focusRingGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OmisuAccent.brandGreen.withValues(alpha: 0.55),
              theme.colorScheme.outline.withValues(alpha: 0.75),
              OmisuAccent.brandGreenDeep.withValues(alpha: 0.35),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        gradient: rim,
        boxShadow: active
            ? [
                BoxShadow(
                  color: OmisuAccent.brandGreen.withValues(alpha: 0.18),
                  blurRadius: 8.r,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(1.r),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Mono label styling shared across header HUD elements.
TextStyle omisuRetroLabelStyle(
  BuildContext context, {
  double size = 11,
  Color? color,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 0.55,
}) {
  return TextStyle(
    fontFamily: OmisuAccent.fontFamily,
    fontSize: size.r,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color ?? Theme.of(context).colorScheme.onSurface,
    height: 1.1,
  );
}
