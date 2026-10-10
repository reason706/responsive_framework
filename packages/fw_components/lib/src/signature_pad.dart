import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

import 'button.dart';

/// Signature pad (+F24).
///
/// A freehand drawing area for capturing signatures. Strokes render in the
/// text role; [onChanged] reports whether any ink is present. [clear] (also
/// exposed as a button when [showClearButton]) wipes the pad.
///
/// The pad is display + capture only: exporting to an image is left to the
/// caller via a [RepaintBoundary] key if needed.
class FwSignaturePad extends StatefulWidget {
  const FwSignaturePad({
    super.key,
    this.onChanged,
    this.strokeWidth = 2,
    this.hintText = 'Sign here',
    this.height = 160,
    this.showClearButton = true,
    this.clearLabel = 'Clear',
  });

  /// Fires with true when the first stroke lands, false when cleared.
  final ValueChanged<bool>? onChanged;
  final double strokeWidth;
  final String hintText;
  final double height;
  final bool showClearButton;
  final String clearLabel;

  @override
  State<FwSignaturePad> createState() => _FwSignaturePadState();
}

class _FwSignaturePadState extends State<FwSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;

  bool get _isEmpty => _strokes.isEmpty;

  void clear() {
    if (_isEmpty) return;
    setState(() {
      _strokes.clear();
      _current = null;
    });
    widget.onChanged?.call(false);
  }

  void _start(Offset point) {
    setState(() {
      _current = [point];
      _strokes.add(_current!);
    });
    if (_strokes.length == 1) widget.onChanged?.call(true);
  }

  void _add(Offset point) {
    setState(() => _current?.add(point));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;

    return Semantics(
      container: true,
      label: 'Signature pad',
      hint: widget.hintText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: colors.of(FwColorRole.surface),
              borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
              border: Border.all(color: colors.of(FwColorRole.border)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.radii.of(FwRadius.md)),
              child: Stack(
                children: [
                  if (_isEmpty)
                    Center(
                      child: ExcludeSemantics(
                        child: Text(
                          widget.hintText,
                          style: theme.typeScale
                              .resolve(FwTextRole.body, context)
                              .copyWith(
                                color: colors.of(FwColorRole.textMuted),
                              ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => _start(d.localPosition),
                      onPanUpdate: (d) => _add(d.localPosition),
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          color: colors.of(FwColorRole.text),
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showClearButton)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FwButton(
                label: widget.clearLabel,
                variant: FwButtonVariant.ghost,
                size: FwSize.sm,
                onPressed: _isEmpty ? null : clear,
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        // A tap without movement: dot the point.
        canvas.drawCircle(stroke.first, strokeWidth / 2, paint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      strokes != oldDelegate.strokes ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}
