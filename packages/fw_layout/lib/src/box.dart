import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// P2.2 — Padding primitive with logical props (the Atlassian Box pattern).
///
/// Every prop is an [FwSpace] token; physical left/right never appear in the
/// API, so RTL correctness falls out of [EdgeInsetsDirectional] by
/// construction. Props compose with "most specific wins" precedence:
///
/// `paddingInlineStart` > `paddingInline` > `padding`
/// `paddingBlockStart` > `paddingBlock` > `padding`
///
/// (and the `End` variants symmetrically).
///
/// Like [FwGap], resolved insets are scaled by the active
/// [FwDensity.gapScale] — padding is control spacing, which density owns.
/// Raw `FwSpaceScale.of` intentionally ignores density; the widget layer
/// opts in, matching [FwSpaceScale.resolveAlias].
///
/// Per the P2.5 margin convention, spacing belongs on the container: use
/// [FwBox] (or a gap stack's `gap`) instead of `margin:` on children.
class FwBox extends StatelessWidget {
  const FwBox({
    super.key,
    required this.child,
    this.padding,
    this.paddingInline,
    this.paddingBlock,
    this.paddingInlineStart,
    this.paddingInlineEnd,
    this.paddingBlockStart,
    this.paddingBlockEnd,
  });

  /// The child the padding wraps.
  final Widget child;

  /// Uniform padding on all four sides (lowest precedence).
  final FwSpace? padding;

  /// Inline-axis (start/end) padding. Beats [padding].
  final FwSpace? paddingInline;

  /// Block-axis (top/bottom) padding. Beats [padding].
  final FwSpace? paddingBlock;

  /// Inline-start padding. Beats [paddingInline].
  final FwSpace? paddingInlineStart;

  /// Inline-end padding. Beats [paddingInline].
  final FwSpace? paddingInlineEnd;

  /// Block-start (top) padding. Beats [paddingBlock].
  final FwSpace? paddingBlockStart;

  /// Block-end (bottom) padding. Beats [paddingBlock].
  final FwSpace? paddingBlockEnd;

  double _px(FwSpace? token, BuildContext context) {
    if (token == null) return 0;
    return context.fwTheme.spaceScale.of(token, context) *
        FwMetrics.of(context).density.gapScale;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: _px(paddingInlineStart ?? paddingInline ?? padding, context),
        end: _px(paddingInlineEnd ?? paddingInline ?? padding, context),
        top: _px(paddingBlockStart ?? paddingBlock ?? padding, context),
        bottom: _px(paddingBlockEnd ?? paddingBlock ?? padding, context),
      ),
      child: child,
    );
  }
}
