import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Border style for [FwDottedBorder].
enum FwBorderStyle {
  /// Round dots.
  dotted,

  /// Short dashes.
  dashed,
}

/// Dotted / dashed border (+U01).
///
/// Wraps [child] in a dotted or dashed rounded-rect border painted with a
/// [CustomPainter]. The border color comes from [colorRole] (a theme role,
/// never a raw color); [strokeWidth], [dashWidth], and [gap] control the
/// pattern. Common for drop zones, empty states, and coupon-style cards.
class FwDottedBorder extends StatelessWidget {
  const FwDottedBorder({
    super.key,
    required this.child,
    this.style = FwBorderStyle.dotted,
    this.colorRole = FwColorRole.border,
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.gap = 4,
    this.radius = FwRadius.md,
    this.padding,
  }) : assert(strokeWidth > 0),
       assert(dashWidth > 0),
       assert(gap >= 0);

  final Widget child;
  final FwBorderStyle style;
  final FwColorRole colorRole;
  final double strokeWidth;
  final double dashWidth;
  final double gap;
  final FwRadius radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return CustomPaint(
      painter: _DottedPainter(
        color: theme.colors.of(colorRole),
        strokeWidth: strokeWidth,
        dashWidth: style == FwBorderStyle.dotted ? strokeWidth : dashWidth,
        gap: gap,
        radius: theme.radii.of(radius),
        roundDots: style == FwBorderStyle.dotted,
      ),
      child: Padding(
        padding:
            padding ?? EdgeInsets.all(theme.spaceScale.of(FwSpace.s4, context)),
        child: child,
      ),
    );
  }
}

class _DottedPainter extends CustomPainter {
  _DottedPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gap,
    required this.radius,
    required this.roundDots,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gap;
  final double radius;
  final bool roundDots;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = roundDots ? StrokeCap.round : StrokeCap.butt;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0.0, metric.length)),
          paint,
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius ||
      roundDots != oldDelegate.roundDots;
}
