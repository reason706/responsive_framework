import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// Viewport classes for grid tokens: compact (phones), medium (tablets /
/// small laptops), expanded (desktops).
enum FwViewportClass { compact, medium, expanded }

/// Grid tokens for one viewport class: column count, gutter, and outer
/// margin. Gutters and margins are [FwLength]s so they resolve against the
/// ambient root metrics.
@immutable
class FwGridSpec {
  const FwGridSpec({
    required this.columns,
    required this.gutter,
    required this.margin,
  });

  final int columns;
  final FwLength gutter;
  final FwLength margin;
}

/// Grid/breakpoint tokens.
///
/// Column counts follow the 4/8/12 convention (compact/medium/expanded);
/// gutters and margins grow with the viewport class. Resolve against the
/// real container width via [of] — never a global screen-width ratio.
@immutable
class FwGrid {
  const FwGrid();

  /// Viewport class for a logical width.
  static FwViewportClass classOf(double width) => width < 600
      ? FwViewportClass.compact
      : width < 1240
      ? FwViewportClass.medium
      : FwViewportClass.expanded;

  /// Token spec for a viewport class.
  static FwGridSpec specFor(FwViewportClass viewportClass) =>
      switch (viewportClass) {
        // Phones: 4 columns, 16px gutters/margins at root 16.
        FwViewportClass.compact => FwGridSpec(
          columns: 4,
          gutter: FwRem(1),
          margin: FwRem(1),
        ),
        // Tablets: 8 columns, 24px gutters/margins at root 16.
        FwViewportClass.medium => FwGridSpec(
          columns: 8,
          gutter: FwRem(1.5),
          margin: FwRem(1.5),
        ),
        // Desktops: 12 columns, 24px gutters, 32px margins at root 16.
        FwViewportClass.expanded => FwGridSpec(
          columns: 12,
          gutter: FwRem(1.5),
          margin: FwRem(2),
        ),
      };

  /// Spec for the current viewport width.
  FwGridSpec of(BuildContext context) =>
      specFor(classOf(MediaQuery.sizeOf(context).width));

  /// Safe-area insets from the platform (notch, system bars). Prefer
  /// [FwResponsiveLayout]/[SafeArea] over reading this directly.
  static EdgeInsets safeAreaOf(BuildContext context) =>
      MediaQuery.paddingOf(context);
}

/// Page scaffold: safe-area insets, responsive grid margins, and a maximum
/// content width.
///
/// Margins come from [FwGrid] tokens for the current viewport class; the
/// content is centered and capped at [maxWidth] on wide screens. This is
/// the recommended top-level wrapper for pages (Patterns tier).
class FwResponsiveLayout extends StatelessWidget {
  const FwResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.safeArea = true,
  });

  final Widget child;

  /// Maximum content width in logical pixels before centering.
  final double maxWidth;

  /// Whether to pad for platform safe areas (notch, system bars).
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final spec = FwGrid.specFor(FwGrid.classOf(width));
        final margin = spec.margin.resolve(context);
        return Padding(
          padding: EdgeInsetsDirectional.only(start: margin, end: margin),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
    return safeArea ? SafeArea(child: body) : body;
  }
}
