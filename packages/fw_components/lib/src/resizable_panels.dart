import 'package:flutter/material.dart';
import 'package:fw_core/fw_core.dart';

/// Resizable split panels.
///
/// Two panes separated by a draggable divider. [ratio] is the first pane's
/// fraction (0..1), clamped to [minRatio]..[maxRatio]. The divider is a
/// slider for assistive tech (arrow keys move it) and honors the 48px
/// minimum touch target across its hit area.
///
/// For [Axis.horizontal] the panes sit side by side; [Axis.vertical]
/// stacks them.
class FwResizablePanels extends StatefulWidget {
  const FwResizablePanels({
    super.key,
    required this.first,
    required this.second,
    this.direction = Axis.horizontal,
    this.initialRatio = 0.5,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.onRatioChanged,
  }) : assert(initialRatio > 0 && initialRatio < 1),
       assert(minRatio > 0 && maxRatio < 1 && minRatio <= maxRatio);

  final Widget first;
  final Widget second;
  final Axis direction;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final ValueChanged<double>? onRatioChanged;

  @override
  State<FwResizablePanels> createState() => _FwResizablePanelsState();
}

class _FwResizablePanelsState extends State<FwResizablePanels> {
  late double _ratio;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
  }

  void _setRatio(double ratio) {
    final clamped = ratio.clamp(widget.minRatio, widget.maxRatio);
    if (clamped != _ratio) {
      setState(() => _ratio = clamped);
      widget.onRatioChanged?.call(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    final colors = theme.colors;
    final horizontal = widget.direction == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mainExtent = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        void dragTo(Offset delta) {
          final dd = horizontal ? delta.dx : delta.dy;
          if (mainExtent > 0) _setRatio(_ratio + dd / mainExtent);
        }

        final divider = Semantics(
          slider: true,
          label: 'Resize panels',
          value: '${(_ratio * 100).round()} percent',
          increasedValue: '${((_ratio + 0.1) * 100).round()} percent',
          decreasedValue: '${((_ratio - 0.1) * 100).round()} percent',
          onIncrease: () => _setRatio(_ratio + 0.1),
          onDecrease: () => _setRatio(_ratio - 0.1),
          child: MouseRegion(
            cursor: horizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: horizontal
                  ? (d) => dragTo(d.delta)
                  : null,
              onVerticalDragUpdate: horizontal ? null : (d) => dragTo(d.delta),
              child: Container(
                width: horizontal ? 48 : double.infinity,
                height: horizontal ? double.infinity : 48,
                alignment: Alignment.center,
                child: Container(
                  width: horizontal ? 4 : 48,
                  height: horizontal ? 48 : 4,
                  decoration: BoxDecoration(
                    color: colors.of(FwColorRole.border),
                    borderRadius: BorderRadius.circular(
                      theme.radii.of(FwRadius.xs),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Flex units keep the ratio exact without pixel math.
        const units = 1000;
        final firstFlex = (_ratio * units).round();
        final children = [
          Flexible(flex: firstFlex, child: widget.first),
          divider,
          Flexible(flex: units - firstFlex, child: widget.second),
        ];

        return horizontal
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }
}
