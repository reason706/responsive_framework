import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Compact color picker (F20+).
///
/// Hue slider + saturation/value pad + preset swatches. Reports the picked
/// color through [onColorSelected] as the pointer moves.
///
/// A picker is a *value* boundary, not a styling API: it trades in raw
/// [Color] data the way a text field trades in [String]s. The E1
/// no-raw-Color rule covers styling parameters; [initialColor], [presets],
/// and [onColorSelected] are the picked value itself (documented exemption
/// in the params scan test).
class FwColorPicker extends StatefulWidget {
  const FwColorPicker({
    super.key,
    required this.onColorSelected,
    this.initialColor = const Color(0xFF1B6DE0),
    this.presets = const [
      Color(0xFF1B6DE0),
      Color(0xFF0E9F6E),
      Color(0xFFE3A008),
      Color(0xFFC81E1E),
      Color(0xFF7C3AED),
      Color(0xFF111928),
    ],
    this.semanticLabel = 'Color picker',
  });

  /// Fires with the picked color while dragging.
  final ValueChanged<Color> onColorSelected;

  /// Starting color (a data value, not a style token).
  final Color initialColor;

  /// Quick-pick swatches.
  final List<Color> presets;

  final String semanticLabel;

  @override
  State<FwColorPicker> createState() => _FwColorPickerState();
}

class _FwColorPickerState extends State<FwColorPicker> {
  late HSVColor _hsv;
  final GlobalKey _padKey = GlobalKey();
  final GlobalKey _hueKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  void _update(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onColorSelected(hsv.toColor());
  }

  /// Local position → saturation/value using the pad's own box.
  void _padTo(Offset local) {
    final box = _padKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final s = box.size;
    _update(
      _hsv
          .withSaturation((local.dx / s.width).clamp(0.0, 1.0))
          .withValue(1 - (local.dy / s.height).clamp(0.0, 1.0)),
    );
  }

  /// Local x → hue using the slider's own box.
  void _hueTo(double dx) {
    final box = _hueKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _update(_hsv.withHue(((dx / box.size.width).clamp(0.0, 1.0) * 360)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final gap = SizedBox(height: theme.spaceScale.of(FwSpace.s3, context));
    final hex =
        '#${_hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: hex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saturation/value pad.
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              key: _padKey,
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _padTo(d.localPosition),
              onPanUpdate: (d) => _padTo(d.localPosition),
              child: CustomPaint(painter: _SvPainter(hue: _hsv.hue)),
            ),
          ),
          gap,
          // Hue slider.
          GestureDetector(
            key: _hueKey,
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => _hueTo(d.localPosition.dx),
            onPanUpdate: (d) => _hueTo(d.localPosition.dx),
            child: SizedBox(
              height: 48,
              child: CustomPaint(painter: _HuePainter(hue: _hsv.hue)),
            ),
          ),
          gap,
          // Preview + hex.
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _hsv.toColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.of(FwColorRole.border)),
                ),
              ),
              SizedBox(width: theme.spaceScale.of(FwSpace.s2, context)),
              ExcludeSemantics(
                child: Text(
                  hex,
                  style: theme.typeScale.resolve(FwTextRole.code, context),
                ),
              ),
            ],
          ),
          gap,
          // Preset swatches wrap instead of overflowing.
          Wrap(
            spacing: theme.spaceScale.of(FwSpace.s2, context),
            runSpacing: theme.spaceScale.of(FwSpace.s2, context),
            children: [
              for (final preset in widget.presets)
                GestureDetector(
                  onTap: () => _update(HSVColor.fromColor(preset)),
                  child: Semantics(
                    button: true,
                    label: 'Preset color',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: preset,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.of(FwColorRole.border),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Saturation/value pad for [hue]: white→hue horizontally, →black vertically.
class _SvPainter extends CustomPainter {
  _SvPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base hue.
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
    // Saturation: white on the left.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    // Value: black at the bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SvPainter oldDelegate) => hue != oldDelegate.hue;
}

/// Hue spectrum bar with a thumb at [hue].
class _HuePainter extends CustomPainter {
  _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Rect.fromLTWH(0, 14, size.width, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(10)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ],
        ).createShader(bar),
    );
    final x = (hue / 360) * size.width;
    canvas.drawCircle(
      Offset(x, 24),
      12,
      Paint()
        ..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x, 24),
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HuePainter oldDelegate) => hue != oldDelegate.hue;
}
