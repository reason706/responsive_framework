import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// Named opacity levels for emphasis, state, and scrims.
///
/// Prefer these over ad-hoc `withValues(alpha: …)` so emphasis stays
/// consistent and themeable.
enum FwOpacity { full, high, medium, disabled, scrim }

/// Theme-resolvable opacity table.
///
/// Defaults come from `tokens.yaml` (`opacity.*`); override per theme for a
/// different emphasis ramp.
@immutable
class FwOpacities {
  const FwOpacities({
    this.full = FwTokenValues.opacityFull,
    this.high = FwTokenValues.opacityHigh,
    this.medium = FwTokenValues.opacityMedium,
    this.disabled = FwTokenValues.opacityDisabled,
    this.scrim = FwTokenValues.opacityScrim,
  });

  /// 1.0. Fully opaque.
  final double full;

  /// 0.87. High-emphasis content on surfaces.
  final double high;

  /// 0.6. Medium-emphasis content: captions, placeholders.
  final double medium;

  /// 0.38. Disabled content (M3 state opacity).
  final double disabled;

  /// 0.32. Modal scrim.
  final double scrim;

  /// Resolves a named opacity level.
  double of(FwOpacity level) => switch (level) {
    FwOpacity.full => full,
    FwOpacity.high => high,
    FwOpacity.medium => medium,
    FwOpacity.disabled => disabled,
    FwOpacity.scrim => scrim,
  };

  FwOpacities copyWith({
    double? full,
    double? high,
    double? medium,
    double? disabled,
    double? scrim,
  }) => FwOpacities(
    full: full ?? this.full,
    high: high ?? this.high,
    medium: medium ?? this.medium,
    disabled: disabled ?? this.disabled,
    scrim: scrim ?? this.scrim,
  );
}
