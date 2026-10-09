import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// L03 — Horizontal stack with a token gap.
///
/// Separators are plain [SizedBox]es, so source order, focus order, and RTL
/// are preserved. Children may use [Expanded]/[Flexible] — this is a [Row],
/// so flex works wherever a [Row] is valid.
class FwHStack extends StatelessWidget {
  const FwHStack({
    super.key,
    required this.children,
    this.gap = FwSpace.s4,
    this.alignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final FwSpace gap;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final gapPx = context.fwTheme.spaceScale.of(gap, context);
    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gapPx),
          children[i],
        ],
      ],
    );
  }
}

/// L03 — Vertical stack with a token gap. See [FwHStack].
class FwVStack extends StatelessWidget {
  const FwVStack({
    super.key,
    required this.children,
    this.gap = FwSpace.s4,
    this.alignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final FwSpace gap;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final gapPx = context.fwTheme.spaceScale.of(gap, context);
    return Column(
      mainAxisAlignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gapPx),
          children[i],
        ],
      ],
    );
  }
}

/// L03 — Stack that lays out horizontally at or above [breakpoint] and
/// vertically below it.
///
/// The threshold resolves against the theme's breakpoints and the available
/// width (container query, not the viewport). Avoid [Expanded]/[Flexible]
/// children unless the cross axis is bounded in both orientations — a flex
/// child that works in the [Row] will fail in the [Column] under unbounded
/// height.
class FwAdaptiveStack extends StatelessWidget {
  const FwAdaptiveStack({
    super.key,
    required this.children,
    this.gap = FwSpace.s4,
    this.breakpoint = FwBreakpoint.md,
    this.horizontalAlignment = MainAxisAlignment.start,
    this.verticalAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final FwSpace gap;
  final FwBreakpoint breakpoint;
  final MainAxisAlignment horizontalAlignment;
  final MainAxisAlignment verticalAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'FwAdaptiveStack requires bounded width to pick an orientation.',
          );
        }
        final threshold = theme.breakpoints.value(breakpoint);
        if (constraints.maxWidth >= threshold) {
          return FwHStack(
            gap: gap,
            alignment: horizontalAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          );
        }
        return FwVStack(
          gap: gap,
          alignment: verticalAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        );
      },
    );
  }
}

/// L04 — Theme-aware [Wrap] facade.
///
/// Token gaps resolve against the root; source order and focus order are
/// preserved (Wrap never reorders). For grid placement, use [FwRow].
class FwWrap extends StatelessWidget {
  const FwWrap({
    super.key,
    required this.children,
    this.gap = FwSpace.s2,
    this.runGap = FwSpace.s2,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  final List<Widget> children;
  final FwSpace gap;
  final FwSpace runGap;
  final Axis direction;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final scale = context.fwTheme.spaceScale;
    return Wrap(
      direction: direction,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: scale.of(gap, context),
      runSpacing: scale.of(runGap, context),
      children: children,
    );
  }
}
