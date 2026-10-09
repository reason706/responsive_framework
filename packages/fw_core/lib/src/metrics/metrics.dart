import 'package:flutter/widgets.dart';

import '../responsive.dart';
import '../theme.dart';

/// Density preference affecting control padding, row gaps, and other
/// semantic spacing. Never shrinks the supported touch target below
/// 48 logical pixels and never reduces body text size.
enum FwDensity {
  /// Tighter control padding and gaps for dense data interfaces.
  compact(0.875),

  /// Default comfortable spacing.
  comfortable(1.0),

  /// Roomier spacing for touch-first or low-vision-friendly layouts.
  spacious(1.25);

  const FwDensity(this.gapScale);

  /// Multiplier applied to *semantic* spacing aliases. Raw spacing tokens
  /// ([FwSpaceScale.of]) are root-relative only and ignore density.
  final double gapScale;
}

/// Root design metrics owned by the application root.
///
/// The root size `R` is the Flutter equivalent of the CSS root font size:
/// `FwRem(n)` resolves to `n * R` logical pixels. It is always a plain
/// positive double — never a `FwRem` referring to itself.
///
/// See ADR-001 for ownership and resolution rules.
@immutable
class FwMetrics {
  const FwMetrics({
    this.rootSize = 16,
    this.responsiveRoot,
    this.density = FwDensity.comfortable,
  }) : assert(rootSize > 0);
  // Note: `rootSize > 0` also rejects NaN in debug builds. Full finiteness
  // is enforced at resolution time (see [FwMetrics.of]) so the constructor
  // can stay const for theme defaults.

  /// Base root size in logical pixels. Default 16.
  final double rootSize;

  /// Optional responsive root, e.g. 16 below `lg` and 18 at `lg`.
  /// Resolves against the explicitly selected responsive width
  /// ([FwContainerQuery]/[FwViewportScope]), never an implicit screen size.
  /// This is an opt-in design choice, not the default behavior.
  final Responsive<double>? responsiveRoot;

  /// Density preference for semantic spacing.
  final FwDensity density;

  /// Effective root size for [width] using [breakpoints].
  double effectiveRootSize(FwBreakpoints breakpoints, double width) {
    final config = responsiveRoot;
    if (config == null) return rootSize;
    final resolved = config.resolve(breakpoints.at(width));
    if (!resolved.isFinite || resolved <= 0) {
      throw StateError(
        'Responsive root sizes must be finite and positive, got $resolved.',
      );
    }
    return resolved;
  }

  /// Nearest explicit [FwRootScope], otherwise the active [FwTheme]'s
  /// configured metrics. Nested color/theme scopes never change the root;
  /// only an explicit nested [FwRootScope] does.
  ///
  /// Validates the root size on the resolution path (release builds included):
  /// it must be finite and positive.
  static FwMetrics of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FwRootScope>();
    final metrics = scope?.metrics ?? FwTheme.of(context).metrics;
    if (!metrics.rootSize.isFinite || metrics.rootSize <= 0) {
      throw StateError(
        'FwMetrics.rootSize must be finite and positive, '
        'got ${metrics.rootSize}.',
      );
    }
    return metrics;
  }

  FwMetrics copyWith({
    double? rootSize,
    Responsive<double>? responsiveRoot,
    FwDensity? density,
  }) {
    return FwMetrics(
      rootSize: rootSize ?? this.rootSize,
      responsiveRoot: responsiveRoot ?? this.responsiveRoot,
      density: density ?? this.density,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FwMetrics &&
          rootSize == other.rootSize &&
          responsiveRoot == other.responsiveRoot &&
          density == other.density;

  @override
  int get hashCode => Object.hash(rootSize, responsiveRoot, density);
}

/// Explicit root-metrics scope. Place at the application root to own `rem`.
///
/// Descendant theme/color overrides inherit this root. A nested [FwRootScope]
/// is an explicit, deliberate root change — never a side effect of overriding
/// colors in a dialog or card.
class FwRootScope extends InheritedWidget {
  const FwRootScope({super.key, required this.metrics, required super.child});

  final FwMetrics metrics;

  @override
  bool updateShouldNotify(FwRootScope oldWidget) =>
      metrics != oldWidget.metrics;
}
