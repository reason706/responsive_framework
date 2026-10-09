import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/intent.dart';

/// Layer 3 — component tokens.
///
/// The primitive layer ([FwColorPrimitives]) holds raw values, the semantic
/// layer ([FwColors]) maps roles onto them, and this layer maps roles onto
/// *component slots*. Component tokens are [ThemeExtension]s so an
/// application can override one component's palette (e.g. brand-tinted
/// buttons) without forking the whole theme, and so tests can inject exact
/// colors. Components read these with a fallback to
/// `FwButtonColors.fromColors(theme.colors)` so they render identically
/// with or without an explicit registration.
///
/// Only components with a real color table get a token class; one-off
/// colors stay as semantic-role references in the widget.
@immutable
class FwButtonColors extends ThemeExtension<FwButtonColors> {
  const FwButtonColors({required this.solid, required this.textTreatment});

  /// Per-intent colors for the filled (solid) treatment: background and
  /// foreground.
  final Map<FwIntent, FwButtonColorSet> solid;

  /// Per-intent colors for the outline, ghost, and link treatments, which
  /// share one foreground-only table (no background fill).
  final Map<FwIntent, FwButtonColorSet> textTreatment;

  /// Builds the default table from semantic roles. No raw colors: every
  /// value resolves through [colors].
  factory FwButtonColors.fromColors(FwColors colors) {
    FwButtonColorSet solidFor(FwIntent intent) {
      final (bg, fg) = intentRoles(intent);
      return FwButtonColorSet(
        background: colors.of(bg),
        foreground: colors.of(fg),
      );
    }

    FwButtonColorSet textFor(FwIntent intent) {
      final (bg, _) = intentRoles(intent);
      return FwButtonColorSet(foreground: colors.of(bg));
    }

    return FwButtonColors(
      solid: {for (final i in FwIntent.values) i: solidFor(i)},
      textTreatment: {for (final i in FwIntent.values) i: textFor(i)},
    );
  }

  /// The color set for a treatment: [filled] selects the solid table,
  /// otherwise the shared outline/ghost/link table.
  FwButtonColorSet setFor({required bool filled, required FwIntent intent}) =>
      (filled ? solid : textTreatment)[intent]!;

  @override
  FwButtonColors copyWith({
    Map<FwIntent, FwButtonColorSet>? solid,
    Map<FwIntent, FwButtonColorSet>? textTreatment,
  }) => FwButtonColors(
    solid: solid ?? this.solid,
    textTreatment: textTreatment ?? this.textTreatment,
  );

  @override
  FwButtonColors lerp(covariant FwButtonColors? other, double t) {
    if (other == null) return this;
    Map<FwIntent, FwButtonColorSet> mix(
      Map<FwIntent, FwButtonColorSet> a,
      Map<FwIntent, FwButtonColorSet> b,
    ) => {for (final i in FwIntent.values) i: a[i]!.lerp(b[i], t)};
    return FwButtonColors(
      solid: mix(solid, other.solid),
      textTreatment: mix(textTreatment, other.textTreatment),
    );
  }
}

/// One slot in a component color table: an optional background fill and a
/// required foreground. A null [background] means a transparent treatment.
@immutable
class FwButtonColorSet {
  const FwButtonColorSet({this.background, required this.foreground});

  final Color? background;
  final Color foreground;

  FwButtonColorSet lerp(FwButtonColorSet? other, double t) {
    if (other == null) return this;
    return FwButtonColorSet(
      background: background == null || other.background == null
          ? (t < 0.5 ? background : other.background)
          : Color.lerp(background, other.background, t),
      foreground: Color.lerp(foreground, other.foreground, t)!,
    );
  }
}
