import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// P2.1 — Token-gated single spacer.
///
/// Replaces `SizedBox(width: 4)` / `SizedBox(height: 8)` with a named token,
/// so every spacer in the framework resolves against the spacing scale.
///
/// The spacer is axis-aware: [Axis.vertical] (the default) inserts height,
/// [Axis.horizontal] inserts width. The token resolves root-relative via
/// [FwSpaceScale.of] and is then scaled by the active [FwDensity.gapScale] —
/// a gap between stacked controls is semantic row spacing, which is exactly
/// what density owns (raw `FwSpaceScale.of` intentionally ignores density;
/// the widget layer opts in). This matches [FwSpaceAlias] resolution via
/// [FwSpaceScale.resolveAlias].
///
/// RTL-neutral: a spacer carries no directionality, so it renders identically
/// under LTR and RTL.
///
/// For gaps *between* children, prefer [FwHStack]/[FwVStack] (non-wrapping)
/// or [FwInline]/[FwWrap] (wrapping) — the container owns the gap. [FwGap]
/// is for the one-off spacer that has no owning container.
class FwGap extends StatelessWidget {
  /// Creates a spacer of [space] on [axis] (vertical by default).
  const FwGap(this.space, {super.key, this.axis = Axis.vertical});

  /// Creates a horizontal spacer of [space].
  const FwGap.horizontal(this.space, {super.key}) : axis = Axis.horizontal;

  /// Creates a vertical spacer of [space].
  const FwGap.vertical(this.space, {super.key}) : axis = Axis.vertical;

  /// The spacing token. Never a raw pixel value.
  final FwSpace space;

  /// Which dimension the spacer occupies.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final px =
        context.fwTheme.spaceScale.of(space, context) *
        FwMetrics.of(context).density.gapScale;
    return axis == Axis.vertical ? SizedBox(height: px) : SizedBox(width: px);
  }
}
