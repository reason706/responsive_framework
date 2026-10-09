import 'package:flutter/widgets.dart';

import '../metrics/metrics.dart';
import '../responsive.dart';
import '../theme.dart';
import '../tokens/spacing.dart';
import 'em.dart';

/// Sealed hierarchy of typed design lengths.
///
/// Lengths resolve to logical pixels against explicit context: root metrics,
/// the explicitly selected responsive width, and typography scopes. They
/// never consult device pixel ratio, and they never multiply by the system
/// text scaler — spacing follows the design root and density, while text
/// scaling is applied exactly once by Flutter's text rendering.
///
/// Constructors are validated factories so invalid configurations fail
/// identically in debug and release builds. See ADR-001.
sealed class FwLength {
  const FwLength._();

  /// Whether resolution needs the explicit responsive width
  /// ([FwContainerQuery]/[FwViewportQuery]).
  bool get needsExplicitWidth => false;

  /// Whether resolution needs an [FwEmScope].
  bool get needsEmScope => false;

  /// Resolves to logical pixels using the surrounding context.
  ///
  /// Reads root metrics, and — only when required — the explicit responsive
  /// width and typography scope. Throws an actionable error when a required
  /// scope is missing instead of silently substituting the screen or zero.
  double resolve(BuildContext context) {
    final metrics = FwMetrics.of(context);
    final breakpoints = FwTheme.of(context).breakpoints;
    final needsWidth = needsExplicitWidth || metrics.responsiveRoot != null;
    final double? width = needsWidth
        ? FwResponsiveScope.widthOf(context)
        : null;
    final rootSize = width == null
        ? metrics.rootSize
        : metrics.effectiveRootSize(breakpoints, width);
    final emSize = needsEmScope ? FwEmScope.declaredSizeOf(context) : null;
    return resolveRaw(
      rootSize: rootSize,
      explicitWidth: width,
      breakpoints: breakpoints,
      emSize: emSize,
    );
  }

  /// Context-free resolution for tooling, tests, and static theme snapshots.
  ///
  /// A null [explicitWidth] means "unknown width": fluid lengths clamp to
  /// their minimum and responsive lengths use their base value.
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  });
}

/// Fixed logical pixels. Unaffected by root metrics, density, breakpoints,
/// and the system text scaler. Use for hairlines and explicit pixel values.
final class FwPx extends FwLength {
  factory FwPx(double pixels) {
    if (!pixels.isFinite || pixels < 0) {
      throw ArgumentError.value(
        pixels,
        'pixels',
        'Must be finite and nonnegative.',
      );
    }
    return FwPx._(pixels);
  }

  const FwPx._(this.pixels) : super._();

  final double pixels;

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) => pixels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FwPx && pixels == other.pixels;

  @override
  int get hashCode => pixels.hashCode;

  @override
  String toString() => 'FwPx($pixels)';
}

/// Root-relative length: `rems * R` where `R` is the resolved root size.
final class FwRem extends FwLength {
  factory FwRem(double rems) {
    if (!rems.isFinite || rems < 0) {
      throw ArgumentError.value(
        rems,
        'rems',
        'Must be finite and nonnegative.',
      );
    }
    return FwRem._(rems);
  }

  const FwRem._(this.rems) : super._();

  final double rems;

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) => rems * rootSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FwRem && rems == other.rems;

  @override
  int get hashCode => rems.hashCode;

  @override
  String toString() => 'FwRem($rems)';
}

/// Typography-relative length: `ems` times the declared (unscaled) size of
/// the nearest [FwEmScope]. Errors when no scope is available.
final class FwEm extends FwLength {
  factory FwEm(double ems) {
    if (!ems.isFinite || ems < 0) {
      throw ArgumentError.value(ems, 'ems', 'Must be finite and nonnegative.');
    }
    return FwEm._(ems);
  }

  const FwEm._(this.ems) : super._();

  final double ems;

  @override
  bool get needsEmScope => true;

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) {
    if (emSize == null) {
      throw StateError(
        'FwEm.resolveRaw requires emSize. In widgets, FwEm.resolve(context) '
        'reads it from the nearest FwEmScope.',
      );
    }
    return ems * emSize;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FwEm && ems == other.ems;

  @override
  int get hashCode => ems.hashCode;

  @override
  String toString() => 'FwEm($ems)';
}

/// Reference to a named spacing token. The token's rem ratio is captured at
/// construction, so token references cannot recurse.
final class FwSpaceRef extends FwLength {
  factory FwSpaceRef(FwSpace token) =>
      FwSpaceRef._(token, FwSpaceScale.remRatio(token));

  const FwSpaceRef._(this.token, this.ratio) : super._();

  final FwSpace token;
  final double ratio;

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) => ratio * rootSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FwSpaceRef && token == other.token;

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() => 'FwSpaceRef(FwSpace.${token.name})';
}

/// Bounded interpolation between two lengths across a width interval.
///
/// At or below [fromWidth] the value is [min]; at or above [toWidth] it is
/// [max]. The value never keeps growing on ultrawide screens. Endpoints are
/// resolved first, then interpolated:
///
/// ```text
/// t = clamp((width - fromWidth) / (toWidth - fromWidth), 0, 1)
/// value = min + (max - min) * t
/// ```
final class FwFluid extends FwLength {
  factory FwFluid({
    required FwLength min,
    required FwLength max,
    required FwPx fromWidth,
    required FwPx toWidth,
  }) {
    if (min is FwFluid || max is FwFluid) {
      throw ArgumentError('FwFluid endpoints cannot themselves be FwFluid.');
    }
    if (fromWidth.pixels >= toWidth.pixels) {
      throw ArgumentError(
        'fromWidth (${fromWidth.pixels}) must be less than '
        'toWidth (${toWidth.pixels}).',
      );
    }
    return FwFluid._(
      min: min,
      max: max,
      fromWidth: fromWidth.pixels,
      toWidth: toWidth.pixels,
    );
  }

  const FwFluid._({
    required this.min,
    required this.max,
    required this.fromWidth,
    required this.toWidth,
  }) : super._();

  final FwLength min;
  final FwLength max;

  /// Logical-pixel bounds of the interpolation interval.
  final double fromWidth;
  final double toWidth;

  @override
  bool get needsExplicitWidth => true;

  @override
  bool get needsEmScope => min.needsEmScope || max.needsEmScope;

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) {
    final lo = min.resolveRaw(
      rootSize: rootSize,
      explicitWidth: explicitWidth,
      breakpoints: breakpoints,
      emSize: emSize,
    );
    final hi = max.resolveRaw(
      rootSize: rootSize,
      explicitWidth: explicitWidth,
      breakpoints: breakpoints,
      emSize: emSize,
    );
    final width = explicitWidth;
    if (width == null) return lo;
    final t = ((width - fromWidth) / (toWidth - fromWidth)).clamp(0.0, 1.0);
    return lo + (hi - lo) * t;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwFluid &&
          min == other.min &&
          max == other.max &&
          fromWidth == other.fromWidth &&
          toWidth == other.toWidth;

  @override
  int get hashCode => Object.hash(min, max, fromWidth, toWidth);

  @override
  String toString() =>
      'FwFluid(min: $min, max: $max, fromWidth: $fromWidth, toWidth: $toWidth)';
}

/// Discrete breakpoint overrides around any [FwLength].
///
/// Wraps the existing [Responsive] contract: `base` is always required and
/// larger overrides inherit downward. A breakpoint activates at its exact
/// minimum width.
final class FwResponsiveLength extends FwLength {
  factory FwResponsiveLength(Responsive<FwLength> value) =>
      FwResponsiveLength._(value);

  const FwResponsiveLength._(this.value) : super._();

  final Responsive<FwLength> value;

  @override
  bool get needsExplicitWidth => true;

  @override
  bool get needsEmScope {
    for (final breakpoint in FwBreakpoint.values) {
      if (value.resolve(breakpoint).needsEmScope) return true;
    }
    return false;
  }

  @override
  double resolveRaw({
    required double rootSize,
    double? explicitWidth,
    FwBreakpoints breakpoints = FwBreakpoints.standard,
    double? emSize,
  }) {
    final breakpoint = explicitWidth == null
        ? FwBreakpoint.xs
        : breakpoints.at(explicitWidth);
    return value.resolve(breakpoint).resolveRaw(
      rootSize: rootSize,
      explicitWidth: explicitWidth,
      breakpoints: breakpoints,
      emSize: emSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwResponsiveLength && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FwResponsiveLength($value)';
}
