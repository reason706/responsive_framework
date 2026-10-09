import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

/// Formats a slider value for display and semantics.
typedef FwSliderFormatter = String Function(double value);

String _defaultFormat(double value, int? divisions, String? unit) {
  final text = divisions == null
      ? value.toStringAsFixed(1)
      : value.round().toString();
  return unit == null ? text : '$text$unit';
}

/// Slider (F09): continuous or discrete, with separated drag/commit events.
///
/// [onChanged] fires continuously during the drag; [onChangeEnd] fires once
/// when the drag commits (pointer up). Callers that write to a model on
/// every frame use [onChanged]; callers that persist or fetch use
/// [onChangeEnd]. The domain is validated: [min] < [max], [divisions] > 0.
///
/// In RTL locales the visual direction flips per the documented Material
/// policy; [onChanged] values always move from [min] to [max] regardless of
/// direction, and semantics announce the formatted value either way.
class FwSlider extends StatelessWidget {
  const FwSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
    this.enabled = true,
    this.unit,
    this.valueFormatter,
    this.showValueBubble = false,
    this.showTicks = false,
    this.axis = Axis.horizontal,
    this.sliderTheme,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max, 'min must be less than max'),
       assert(divisions == null || divisions > 0, 'divisions must be positive'),
       assert(value >= min && value <= max, 'value must be within min..max');

  /// Accessible name for the slider.
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  /// Discrete steps. Null means continuous.
  final int? divisions;

  /// Fires once when the drag commits.
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  /// Unit suffix for the readout, e.g. '%'.
  final String? unit;
  final FwSliderFormatter? valueFormatter;

  /// Show the Material value indicator while dragging.
  final bool showValueBubble;

  /// Show tick marks (discrete sliders only).
  final bool showTicks;
  final Axis axis;

  /// Full SliderThemeData override, merged over the token defaults.
  final SliderThemeData? sliderTheme;
  final FocusNode? focusNode;
  final bool autofocus;

  String _formatted(double v) =>
      valueFormatter?.call(v) ?? _defaultFormat(v, divisions, unit);

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final formatted = _formatted(value.clamp(min, max));

    final slider = Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      label: showValueBubble ? formatted : null,
      onChanged: enabled && onChanged != null
          ? (v) => onChanged!(v.clamp(min, max))
          : null,
      onChangeEnd: enabled ? (v) => onChangeEnd?.call(v.clamp(min, max)) : null,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticFormatterCallback: (_) => formatted,
    );

    final themed = SliderTheme(
      // A caller-supplied theme replaces the token defaults wholesale;
      // SliderThemeData has no partial merge.
      data:
          sliderTheme ??
          SliderTheme.of(context).copyWith(
            activeTrackColor: colors.of(FwColorRole.primary),
            inactiveTrackColor: colors.of(FwColorRole.surfaceContainerHighest),
            thumbColor: colors.of(FwColorRole.primary),
            overlayColor: colors
                .of(FwColorRole.primary)
                .withValues(alpha: 0.12),
            valueIndicatorColor: colors.of(FwColorRole.inverseSurface),
            valueIndicatorTextStyle: theme.typeScale
                .resolve(FwTextRole.label, context)
                .copyWith(color: colors.of(FwColorRole.onInverseSurface)),
            tickMarkShape: showTicks && divisions != null
                ? const RoundSliderTickMarkShape()
                : SliderTickMarkShape.noTickMark,
          ),
      child: axis == Axis.horizontal
          ? slider
          : RotatedBox(quarterTurns: 3, child: slider),
    );

    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.typeScale.resolve(FwTextRole.label, context),
              ),
              const Spacer(),
              // Visual only: the slider node announces the value.
              ExcludeSemantics(
                child: Text(
                  formatted,
                  style: theme.typeScale
                      .resolve(FwTextRole.label, context)
                      .copyWith(color: colors.of(FwColorRole.textMuted)),
                ),
              ),
            ],
          ),
          if (axis == Axis.horizontal)
            themed
          else
            SizedBox(height: 160, child: Center(child: themed)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular slider (F09+ expansion).
// ---------------------------------------------------------------------------

/// Circular slider: drag around a ring to choose a value in [min]..[max].
///
/// Direct manipulation — no animation is involved, so there is nothing for
/// reduced-motion to collapse. Keyboard users get arrow-key stepping and a
/// slider semantics node with announced values.
class FwCircularSlider extends StatefulWidget {
  const FwCircularSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.onChangeEnd,
    this.enabled = true,
    this.size = 160,
    this.strokeWidth = 12,
    this.unit,
    this.valueFormatter,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min < max, 'min must be less than max'),
       assert(value >= min && value <= max, 'value must be within min..max');

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final double size;
  final double strokeWidth;
  final String? unit;
  final FwSliderFormatter? valueFormatter;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<FwCircularSlider> createState() => _FwCircularSliderState();
}

class _FwCircularSliderState extends State<FwCircularSlider> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(FwCircularSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == null && oldWidget.focusNode != null) {
      _internalFocusNode = FocusNode();
    } else if (widget.focusNode != null && oldWidget.focusNode == null) {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  double get _fraction =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  String _formatted(double v) =>
      widget.valueFormatter?.call(v) ?? _defaultFormat(v, null, widget.unit);

  void _updateFromOffset(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = local - center;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final fraction = (angle / (math.pi * 2)).clamp(0.0, 1.0);
    final next = (widget.min + fraction * (widget.max - widget.min)).clamp(
      widget.min,
      widget.max,
    );
    widget.onChanged?.call(next);
  }

  void _step(int direction) {
    final step = (widget.max - widget.min) / 20;
    final next = (widget.value + direction * step).clamp(
      widget.min,
      widget.max,
    );
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowRight => () {
        _step(1);
        return KeyEventResult.handled;
      }(),
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowLeft => () {
        _step(-1);
        return KeyEventResult.handled;
      }(),
      _ => KeyEventResult.ignored,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final interactive = widget.enabled && widget.onChanged != null;
    final formatted = _formatted(widget.value);

    return Semantics(
      container: true,
      label: widget.label,
      value: formatted,
      slider: true,
      increasedValue: _formatted(
        (widget.value + (widget.max - widget.min) / 20).clamp(
          widget.min,
          widget.max,
        ),
      ),
      decreasedValue: _formatted(
        (widget.value - (widget.max - widget.min) / 20).clamp(
          widget.min,
          widget.max,
        ),
      ),
      onIncrease: interactive ? () => _step(1) : null,
      onDecrease: interactive ? () => _step(-1) : null,
      enabled: interactive,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) =>
            interactive ? _handleKey(event) : KeyEventResult.ignored,
        child: GestureDetector(
          onPanStart: interactive
              ? (details) => _updateFromOffset(
                  details.localPosition,
                  Size(widget.size, widget.size),
                )
              : null,
          onPanUpdate: interactive
              ? (details) => _updateFromOffset(
                  details.localPosition,
                  Size(widget.size, widget.size),
                )
              : null,
          onPanEnd: interactive
              ? (_) => widget.onChangeEnd?.call(widget.value)
              : null,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _RingPainter(
                fraction: _fraction,
                trackColor: colors.of(FwColorRole.surfaceContainerHighest),
                activeColor: colors.of(FwColorRole.primary),
                thumbColor: colors.of(FwColorRole.primary),
                strokeWidth: widget.strokeWidth,
                enabled: widget.enabled,
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
                    ExcludeSemantics(
                      child: Text(
                        widget.label,
                        style: theme.typeScale
                            .resolve(FwTextRole.caption, context)
                            .copyWith(color: colors.of(FwColorRole.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.trackColor,
    required this.activeColor,
    required this.thumbColor,
    required this.strokeWidth,
    required this.enabled,
  });

  final double fraction;
  final Color trackColor;
  final Color activeColor;
  final Color thumbColor;
  final double strokeWidth;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const start = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final activePaint = Paint()
        ..color = enabled ? activeColor : activeColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        fraction * math.pi * 2,
        false,
        activePaint,
      );
    }

    // Thumb dot at the value angle.
    final angle = start + fraction * math.pi * 2;
    final thumbCenter =
        center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      thumbCenter,
      strokeWidth * 0.9,
      Paint()..color = enabled ? thumbColor : thumbColor.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      trackColor != oldDelegate.trackColor ||
      activeColor != oldDelegate.activeColor ||
      enabled != oldDelegate.enabled;
}
