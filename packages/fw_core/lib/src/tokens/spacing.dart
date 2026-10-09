import 'package:flutter/widgets.dart';

import '../lengths/length.dart';
import '../metrics/metrics.dart';
import '../responsive.dart';

/// Named spacing tokens; raw logical pixels remain explicitly separate.
enum FwSpace { s0, s1, s2, s3, s4, s5, s6, s8, s10, s12, s16, s24 }

/// Semantic spacing aliases. Components prefer these over raw tokens where
/// the purpose matters, so a theme can compact forms without changing every
/// spacing token everywhere.
enum FwSpaceAlias {
  /// Horizontal padding inside controls.
  controlInline,

  /// Vertical padding inside controls.
  controlBlock,

  /// Gap between a field and its label/helper/error, and between fields.
  fieldGap,

  /// Padding inside cards and similar surfaces.
  cardInset,

  /// Page-level outer padding.
  pageInset,

  /// Gap between major page sections.
  sectionGap,

  /// Padding inside overlays (dialogs, sheets, popovers).
  overlayInset,
}

/// Root-relative named spacing scale with semantic aliases.
///
/// Token ratios preserve the familiar 4-logical-pixel rhythm at the default
/// root of 16: `s4` resolves to exactly 16 logical pixels, matching the
/// legacy [FwSpacing] pixel scale at root 16 (numeric parity requirement).
///
/// Raw tokens are root-relative only. Semantic aliases additionally apply the
/// active [FwDensity] gap scale; neither is ever multiplied by the system
/// text scaler.
@immutable
class FwSpaceScale {
  const FwSpaceScale();

  /// Root ratios for each named token (multiples of the root size).
  static double remRatio(FwSpace token) => switch (token) {
    FwSpace.s0 => 0,
    FwSpace.s1 => 0.25,
    FwSpace.s2 => 0.5,
    FwSpace.s3 => 0.75,
    FwSpace.s4 => 1,
    FwSpace.s5 => 1.25,
    FwSpace.s6 => 1.5,
    FwSpace.s8 => 2,
    FwSpace.s10 => 2.5,
    FwSpace.s12 => 3,
    FwSpace.s16 => 4,
    FwSpace.s24 => 6,
  };

  /// Resolves a named token to logical pixels against root metrics.
  ///
  /// Unlike the legacy context-free [FwSpacing.of], this honors an explicit
  /// responsive root. At the default root of 16 the results match
  /// `FwSpacing(unit: 4)` exactly.
  double of(FwSpace token, BuildContext context) =>
      FwSpaceRef(token).resolve(context);

  /// Default typed value for a semantic alias (before density scaling).
  ///
  /// Defaults from the design-system spec: page inset 1rem narrow, 1.5rem
  /// medium, 2rem wide; card inset 1rem; field gap 0.75–1rem; section gap
  /// fluid 2–4rem.
  static FwLength aliasValue(FwSpaceAlias alias) => switch (alias) {
    FwSpaceAlias.controlInline => FwRem(1),
    FwSpaceAlias.controlBlock => FwRem(0.5),
    FwSpaceAlias.fieldGap => FwResponsiveLength(
      Responsive(base: FwRem(0.75), md: FwRem(1)),
    ),
    FwSpaceAlias.cardInset => FwRem(1),
    FwSpaceAlias.pageInset => FwResponsiveLength(
      Responsive(base: FwRem(1), md: FwRem(1.5), lg: FwRem(2)),
    ),
    FwSpaceAlias.sectionGap => FwFluid(
      min: FwRem(2),
      max: FwRem(4),
      fromWidth: FwPx(360),
      toWidth: FwPx(1200),
    ),
    FwSpaceAlias.overlayInset => FwRem(1.5),
  };

  /// Resolves a semantic alias, applying the active density gap scale.
  ///
  /// Density never shrinks the supported 48-logical-pixel touch target and
  /// never changes body text size; it adjusts control padding, row gaps,
  /// and visual minimums only.
  double resolveAlias(FwSpaceAlias alias, BuildContext context) {
    final metrics = FwMetrics.of(context);
    return aliasValue(alias).resolve(context) * metrics.density.gapScale;
  }
}
