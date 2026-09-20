import 'package:flutter/material.dart';
import 'package:omisu/widgets/neo_glass.dart';
import 'package:omisu/widgets/omisu/omisu_gradient_border.dart';

/// Standard OmiSU panel: frosted glass fill with an optional gradient rim.
class OmisuGlassPanel extends StatelessWidget {
  const OmisuGlassPanel({
    super.key,
    required this.child,
    this.cornerRadius = 20,
    this.padding,
    this.gradientBorder = false,
    this.borderWidth = 1.5,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry? padding;
  final bool gradientBorder;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final panel = NeoGlass(
      cornerRadius: cornerRadius,
      padding: padding,
      tint: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      child: child,
    );

    if (!gradientBorder) return panel;

    return OmisuGradientBorder(
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      child: panel,
    );
  }
}
