import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// L05 — Responsive grid that fits as many columns as the available width
/// allows.
///
/// Columns are computed from the bounded width: with gap `g` and minimum
/// item width `m`, the column count is `clamp(((W + g) / (m + g)).floor(),
/// 1, maxColumns ?? ∞)`. Item keys stay stable across resizes because the
/// delegate only changes the count, never the item order.
///
/// The default constructor embeds in a page ([shrinkWrap]); use
/// [FwAutoGrid.builder] for large or infinite collections, which builds
/// lazily in its own scrollable.
class FwAutoGrid extends StatelessWidget {
  const FwAutoGrid({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.maxColumns,
    this.gap = FwSpace.s4,
    this.aspectRatio,
    this.controller,
    this.padding,
  }) : assert(minItemWidth > 0, 'minItemWidth must be positive.'),
       assert(
         maxColumns == null || maxColumns > 0,
         'maxColumns must be positive.',
       ),
       itemCount = null,
       itemBuilder = null;

  const FwAutoGrid.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 240,
    this.maxColumns,
    this.gap = FwSpace.s4,
    this.aspectRatio,
    this.controller,
    this.padding,
  }) : assert(minItemWidth > 0, 'minItemWidth must be positive.'),
       assert(
         maxColumns == null || maxColumns > 0,
         'maxColumns must be positive.',
       ),
       children = const [];

  final List<Widget> children;
  final int? itemCount;
  final Widget Function(BuildContext context, int index)? itemBuilder;

  /// Minimum item width in logical pixels (a layout decision, like CSS
  /// `minmax()` — intentionally not root-relative).
  final double minItemWidth;
  final int? maxColumns;
  final FwSpace gap;
  final double? aspectRatio;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  /// Computes the column count for [width] and gap [gapPx].
  static int columnsFor({
    required double width,
    required double minItemWidth,
    required double gapPx,
    int? maxColumns,
  }) {
    final count = math.max(
      1,
      ((width + gapPx) / (minItemWidth + gapPx)).floor(),
    );
    return maxColumns == null ? count : math.min(count, maxColumns);
  }

  SliverGridDelegate _delegate(int columns, double gapPx) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: gapPx,
        crossAxisSpacing: gapPx,
        childAspectRatio: aspectRatio ?? 1,
      );

  @override
  Widget build(BuildContext context) {
    final scale = context.fwTheme.spaceScale;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'FwAutoGrid requires bounded width to compute columns.',
          );
        }
        final gapPx = scale.of(gap, context);
        final columns = columnsFor(
          width: constraints.maxWidth,
          minItemWidth: minItemWidth,
          gapPx: gapPx,
          maxColumns: maxColumns,
        );
        if (itemBuilder != null) {
          return GridView.builder(
            controller: controller,
            padding: padding,
            gridDelegate: _delegate(columns, gapPx),
            itemCount: itemCount,
            itemBuilder: itemBuilder!,
          );
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: gapPx,
          crossAxisSpacing: gapPx,
          childAspectRatio: aspectRatio ?? 1,
          children: children,
        );
      },
    );
  }
}
