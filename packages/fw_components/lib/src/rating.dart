import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fw_core/fw_core.dart';

/// Read-only rating display (F21+).
///
/// [value] may be fractional (e.g. 3.5); the last star clips proportionally.
/// The stars are decorative — the whole widget is one semantic node with the
/// value text. For interactive input use [FwRatingInput].
class FwRatingDisplay extends StatelessWidget {
  const FwRatingDisplay({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 24,
    this.semanticLabel,
  }) : assert(max > 0, 'max must be positive'),
       assert(value >= 0 && value <= max, 'value must be within 0..max');

  final double value;
  final int max;
  final double size;

  /// Accessible label. Defaults to "$value out of $max".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final filled = colors.of(FwColorRole.warning);
    final empty = colors.of(FwColorRole.surfaceContainerHighest);

    Widget star(int i) {
      final fill = (value - i).clamp(0.0, 1.0);
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Icon(Icons.star_border, size: size, color: empty),
            if (fill > 0)
              ClipRect(
                clipper: _FractionClip(fill),
                child: Icon(Icons.star, size: size, color: filled),
              ),
          ],
        ),
      );
    }

    return Semantics(
      label: semanticLabel ?? '$value out of $max',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < max; i++) star(i)],
      ),
    );
  }
}

class _FractionClip extends CustomClipper<Rect> {
  _FractionClip(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClip oldClipper) =>
      fraction != oldClipper.fraction;
}

/// Interactive rating input (F21+).
///
/// Tap or drag across the stars; arrow keys step by [step]. The stars are
/// decorative — one slider semantic node carries the value and
/// increase/decrease actions.
class FwRatingInput extends StatefulWidget {
  const FwRatingInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.step = 1.0,
    this.size = 32,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  }) : assert(max > 0, 'max must be positive'),
       assert(step > 0, 'step must be positive');

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final int max;
  final double step;
  final double size;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<FwRatingInput> createState() => _FwRatingInputState();
}

class _FwRatingInputState extends State<FwRatingInput> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _internalFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(FwRatingInput oldWidget) {
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

  double _snap(double v) =>
      (v / widget.step).round() * widget.step.clamp(0.0, widget.max.toDouble());

  void _update(double v) {
    final next = _snap(v).clamp(0.0, widget.max.toDouble());
    widget.onChanged?.call(next);
  }

  void _updateFromOffset(Offset local, double width) {
    final fraction = (local.dx / width).clamp(0.0, 1.0);
    _update(fraction * widget.max);
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.arrowUp => () {
        _update(widget.value + widget.step);
        return KeyEventResult.handled;
      }(),
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowDown => () {
        _update(widget.value - widget.step);
        return KeyEventResult.handled;
      }(),
      _ => KeyEventResult.ignored,
    };
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled && widget.onChanged != null;
    final formatted = '${widget.value} out of ${widget.max}';

    return Semantics(
      container: true,
      label: widget.label,
      value: formatted,
      slider: true,
      increasedValue:
          '${_snap(widget.value + widget.step)} out of ${widget.max}',
      decreasedValue:
          '${_snap(widget.value - widget.step)} out of ${widget.max}',
      onIncrease: interactive
          ? () => _update(widget.value + widget.step)
          : null,
      onDecrease: interactive
          ? () => _update(widget.value - widget.step)
          : null,
      enabled: interactive,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) =>
            interactive ? _handleKey(event) : KeyEventResult.ignored,
        child: GestureDetector(
          onTapDown: interactive
              ? (details) => _updateFromOffset(
                  details.localPosition,
                  context.size?.width ?? widget.size * widget.max,
                )
              : null,
          onHorizontalDragUpdate: interactive
              ? (details) => _updateFromOffset(
                  details.localPosition,
                  context.size?.width ?? widget.size * widget.max,
                )
              : null,
          child: ExcludeSemantics(
            child: FwRatingDisplay(
              value: widget.value,
              max: widget.max,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}
