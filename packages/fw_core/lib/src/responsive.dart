import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Mobile-first breakpoint names. Thresholds are configurable logical pixels.
enum FwBreakpoint { xs, sm, md, lg, xl, xxl }

/// A value that always resolves, even below its first override.
///
/// Null overrides mean "inherit". Nullable resolved values are intentionally
/// unsupported; use an explicit optional-value wrapper if needed.
@immutable
class Responsive<T extends Object> {
  const Responsive({
    required this.base,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  });

  const Responsive.all(T value)
    : base = value,
      sm = null,
      md = null,
      lg = null,
      xl = null,
      xxl = null;

  final T base;
  final T? sm;
  final T? md;
  final T? lg;
  final T? xl;
  final T? xxl;

  T resolve(FwBreakpoint breakpoint) {
    final values = [base, sm, md, lg, xl, xxl];
    for (var index = breakpoint.index; index > 0; index--) {
      final value = values[index];
      if (value != null) return value;
    }
    return base;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Responsive<T> &&
          base == other.base &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          xxl == other.xxl;

  @override
  int get hashCode => Object.hash(base, sm, md, lg, xl, xxl);

  @override
  String toString() =>
      'Responsive(base: $base, sm: $sm, md: $md, lg: $lg, xl: $xl, xxl: $xxl)';
}

/// Ordered viewport/container thresholds in logical pixels.
@immutable
class FwBreakpoints {
  factory FwBreakpoints({
    double sm = 576,
    double md = 768,
    double lg = 992,
    double xl = 1200,
    double xxl = 1400,
  }) {
    final values = [0.0, sm, md, lg, xl, xxl];
    for (var index = 1; index < values.length; index++) {
      if (!values[index].isFinite || values[index] <= values[index - 1]) {
        throw ArgumentError(
          'Breakpoints must be finite and strictly increasing.',
        );
      }
    }
    return FwBreakpoints._(sm, md, lg, xl, xxl);
  }

  const FwBreakpoints._(this.sm, this.md, this.lg, this.xl, this.xxl);

  static const standard = FwBreakpoints._(576, 768, 992, 1200, 1400);

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  FwBreakpoint at(double width) {
    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Must be finite and nonnegative.',
      );
    }
    if (width >= xxl) return FwBreakpoint.xxl;
    if (width >= xl) return FwBreakpoint.xl;
    if (width >= lg) return FwBreakpoint.lg;
    if (width >= md) return FwBreakpoint.md;
    if (width >= sm) return FwBreakpoint.sm;
    return FwBreakpoint.xs;
  }
}

/// Explicit responsive width for descendants. A nested scope takes precedence.
class FwResponsiveScope extends InheritedWidget {
  FwResponsiveScope({super.key, required this.width, required super.child}) {
    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Must be finite and nonnegative.',
      );
    }
  }

  final double width;

  static double widthOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FwResponsiveScope>();
    if (scope == null) {
      throw FlutterError(
        'No FwResponsiveScope found. Wrap content in FwContainerQuery or '
        'FwViewportQuery to choose its responsive measurement explicitly.',
      );
    }
    return scope.width;
  }

  @override
  bool updateShouldNotify(FwResponsiveScope oldWidget) =>
      width != oldWidget.width;
}

/// Makes descendants respond to available parent width, not screen width.
class FwContainerQuery extends StatelessWidget {
  const FwContainerQuery({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth) {
        throw FlutterError(
          'FwContainerQuery requires bounded width. Place it inside a SizedBox '
          'or a parent with finite horizontal constraints.',
        );
      }
      return FwResponsiveScope(width: constraints.maxWidth, child: child);
    },
  );
}

/// Makes descendants respond to the viewport, even inside a narrow panel.
class FwViewportQuery extends StatelessWidget {
  const FwViewportQuery({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FwResponsiveScope(width: MediaQuery.sizeOf(context).width, child: child);
}

extension FwResponsiveContext on BuildContext {
  FwBreakpoint get fwBreakpoint =>
      FwTheme.of(this).breakpoints.at(FwResponsiveScope.widthOf(this));

  T resolve<T extends Object>(Responsive<T> value) =>
      value.resolve(fwBreakpoint);
}
