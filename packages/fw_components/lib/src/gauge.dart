import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Formats a gauge value for display and semantics.
typedef FwGaugeFormatter = String Function(double value);

String _defaultGaugeFormat(double value, String? unit) {
  final text = value.round().toString();
  return unit == null ? text : '$text$unit';
}

/// Gauge/meter (+M12): a radial arc showing [value] in [min]..[max].
///
/// Display-only — no gestures. The arc fills from [startAngle] over
/// [sweepAngle] (radians, clockwise from the positive x-axis); the default
/// is a 240° gauge with a gap at the bottom. Ticks mark [tickCount]
/// divisions; the center shows the formatted value and [label].
///
/// Color comes from [intent] (resolved through [intentRoles]), never a raw
/// color. Semantics expose the label and the formatted value as a meter.
class FwGauge extends StatelessWidget {
  const FwGauge({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.size = 160,
    this.strokeWidth = 12,
    this.unit,
    this.label,
    this.valueFormatter,
    this.tickCount = 5,
    this.intent = FwIntent.primary,
    this.startAngle = math.pi * 0.75,
    this.sweepAngle = math.pi * 1.5,
    this.semanticLabel,
  }) : assert(min < max, 'min must be less than max'),
       assert(tickCount >= 0, 'tickCount must be non-negative');

  /// Value shown (clamped to [min]..[max]).
  final double value;
  final double min;
  final double max;

  /// Widget diameter.
  final double size;
  final double strokeWidth;

  /// Unit suffix for the readout, e.g. '%'.
  final String? unit;

  /// Caption under the value.
  final String? label;
  final FwGaugeFormatter? valueFormatter;

  /// Number of tick divisions across the sweep.
  final int tickCount;

  /// Semantic intent driving the arc color.
  final FwIntent intent;

  /// Arc start, in radians clockwise from the positive x-axis.
  final double startAngle;

  /// Arc sweep, in radians clockwise.
  final double sweepAngle;

  /// Accessible name. Defaults to [label].
  final String? semanticLabel;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  String _formatted(double v) =>
      valueFormatter?.call(v) ?? _defaultGaugeFormat(v, unit);

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final (fillRole, _) = intentRoles(intent);
    final formatted = _formatted(value.clamp(min, max));

    return Semantics(
      label: semanticLabel ?? label ?? 'Gauge',
      value: formatted,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GaugePainter(
            fraction: _fraction,
            startAngle: startAngle,
            sweepAngle: sweepAngle,
            trackColor: colors.of(FwColorRole.surfaceContainerHighest),
            fillColor: colors.of(fillRole),
            tickColor: colors.of(FwColorRole.textMuted),
            strokeWidth: strokeWidth,
            tickCount: tickCount,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    formatted,
                    style: theme.typeScale.resolve(FwTextRole.h4, context),
                  ),
                ),
                if (label != null)
                  ExcludeSemantics(
                    child: Text(
                      label!,
                      style: theme.typeScale
                          .resolve(FwTextRole.caption, context)
                          .copyWith(color: colors.of(FwColorRole.textMuted)),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.startAngle,
    required this.sweepAngle,
    required this.trackColor,
    required this.fillColor,
    required this.tickColor,
    required this.strokeWidth,
    required this.tickCount,
  });

  final double fraction;
  final double startAngle;
  final double sweepAngle;
  final Color trackColor;
  final Color fillColor;
  final Color tickColor;
  final double strokeWidth;
  final int tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc.
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Filled portion.
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * fraction,
        false,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ticks.
    if (tickCount > 0) {
      final tickPaint = Paint()
        ..color = tickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final outer = radius + strokeWidth / 2 + 6;
      final inner = radius + strokeWidth / 2 + 2;
      for (var i = 0; i <= tickCount; i++) {
        final angle = startAngle + sweepAngle * (i / tickCount);
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * inner,
          center + Offset(math.cos(angle), math.sin(angle)) * outer,
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      startAngle != oldDelegate.startAngle ||
      sweepAngle != oldDelegate.sweepAngle ||
      trackColor != oldDelegate.trackColor ||
      fillColor != oldDelegate.fillColor ||
      tickCount != oldDelegate.tickCount;
}
