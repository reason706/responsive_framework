import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// P2.4 — Wrapping horizontal flow (the Atlassian Inline pattern).
///
/// Like [FwHStack] but wraps: children flow along the inline axis
/// (left-to-right in LTR, right-to-left in RTL) onto new rows when they run
/// out of room. [gap] is the inline (main-axis) gap between siblings;
/// [rowGap] is the block gap between rows. Both are [FwSpace] tokens scaled
/// by the active [FwDensity.gapScale], like [FwGap].
///
/// Which horizontal primitive to reach for:
/// - [FwHStack] — single row, never wraps, flex children allowed.
/// - [FwInline] — wraps, token gaps, no flex children (this widget).
/// - [FwWrap] — the full [Wrap] facade (direction, run alignment).
class FwInline extends StatelessWidget {
  const FwInline({
    super.key,
    required this.children,
    this.gap = FwSpace.s2,
    this.rowGap = FwSpace.s2,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  /// The children to flow. Source order and focus order are preserved —
  /// [Wrap] never reorders.
  final List<Widget> children;

  /// Inline-axis gap between siblings on the same row.
  final FwSpace gap;

  /// Block-axis gap between rows.
  final FwSpace rowGap;

  /// How each row aligns on the inline axis.
  final WrapAlignment alignment;

  /// How children align on the block axis within a row.
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final scale = context.fwTheme.spaceScale;
    final density = FwMetrics.of(context).density.gapScale;
    return Wrap(
      direction: Axis.horizontal,
      spacing: scale.of(gap, context) * density,
      runSpacing: scale.of(rowGap, context) * density,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
