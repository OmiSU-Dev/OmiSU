import 'package:flutter/material.dart';
import 'package:omisu/themes/omisu_accent.dart';

/// Gradient rim wrapper used for focus states and hero panels.
class OmisuGradientBorder extends StatelessWidget {
  const OmisuGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.cornerRadius = 14,
    this.colors,
    this.padding,
  });

  final Widget child;
  final double borderWidth;
  final double cornerRadius;
  final List<Color>? colors;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? OmisuAccent.focusGradient;
    final innerRadius = (cornerRadius - borderWidth).clamp(0.0, cornerRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}
