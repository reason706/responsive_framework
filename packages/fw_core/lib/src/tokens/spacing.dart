import 'package:flutter/widgets.dart';

import '../lengths/length.dart';
import '../metrics/metrics.dart';
import '../responsive.dart';
import 'tokens.g.dart';

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
/// The scale follows an 8px base rhythm with a documented 4px exception for
/// the smallest gap (`s1` = 0.25rem = 4px at root 16) — the same convention
/// the NoNameYet case study documents (`$spacing-4` alongside its 8px
/// steps). Steps are 8px apart from `s2` up, with wider jumps (`s16`, `s24`)
/// for section-scale spacing.
///
/// Naming: t-shirt labels (`s1`…`s24`) rather than px values. NoNameYet names
/// spacing `$spacing-4`…`$spacing-160` by pixel value; both conventions are
/// valid. T-shirt labels were chosen because these values are
/// root-relative — `s4` is 1rem (16px at root 16, 18px at root 18) — so a
/// px-value name would mislead at non-default roots.
///
/// Raw tokens are root-relative only. Semantic aliases additionally apply the
/// active [FwDensity] gap scale; neither is ever multiplied by the system
/// text scaler.
@immutable
class FwSpaceScale {
  const FwSpaceScale();

  /// Root ratios for each named token (multiples of the root size).
  ///
  /// Generated from tokens.yaml; the source of truth for the scale.
  static double remRatio(FwSpace token) => switch (token) {
    FwSpace.s0 => FwTokenValues.spaceS0Rem,
    FwSpace.s1 => FwTokenValues.spaceS1Rem,
    FwSpace.s2 => FwTokenValues.spaceS2Rem,
    FwSpace.s3 => FwTokenValues.spaceS3Rem,
    FwSpace.s4 => FwTokenValues.spaceS4Rem,
    FwSpace.s5 => FwTokenValues.spaceS5Rem,
    FwSpace.s6 => FwTokenValues.spaceS6Rem,
    FwSpace.s8 => FwTokenValues.spaceS8Rem,
    FwSpace.s10 => FwTokenValues.spaceS10Rem,
    FwSpace.s12 => FwTokenValues.spaceS12Rem,
    FwSpace.s16 => FwTokenValues.spaceS16Rem,
    FwSpace.s24 => FwTokenValues.spaceS24Rem,
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
