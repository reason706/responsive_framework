import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// What happens to a hidden child of [FwShow].
enum FwVisibilityMode {
  /// Unmounts the child. Cheapest; state is lost.
  remove,

  /// Keeps the child mounted (state retained) but removes it from layout,
  /// focus, and semantics. Has a documented runtime cost — prefer [remove]
  /// for content that is rarely shown.
  retain,
}

/// L06 — Conditionally shows a child by boolean and/or width range.
///
/// Visibility is the AND of [when], [above] (width >= threshold), and
/// [below] (width < threshold). Thresholds resolve against the theme's
/// breakpoints and the available width.
///
/// Hidden children never remain focusable or visible to semantics, in both
/// modes: [remove] unmounts; [retain] wraps the hidden child in
/// [ExcludeFocus] and [ExcludeSemantics] while keeping its state.
class FwShow extends StatelessWidget {
  const FwShow({
    super.key,
    required this.child,
    this.when = true,
    this.above,
    this.below,
    this.mode = FwVisibilityMode.remove,
  });

  final Widget child;
  final bool when;
  final FwBreakpoint? above;
  final FwBreakpoint? below;
  final FwVisibilityMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'FwShow requires bounded width for breakpoint conditions.',
          );
        }
        final width = constraints.maxWidth;
        var visible = when;
        if (above != null) {
          visible = visible && width >= theme.breakpoints.value(above!);
        }
        if (below != null) {
          visible = visible && width < theme.breakpoints.value(below!);
        }
        if (mode == FwVisibilityMode.remove) {
          return visible ? child : const SizedBox.shrink();
        }
        return Visibility(
          visible: visible,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: false,
          child: ExcludeFocus(
            excluding: !visible,
            child: ExcludeSemantics(excluding: !visible, child: child),
          ),
        );
      },
    );
  }
}

/// L06 — Builds content from the available width and breakpoint.
///
/// For custom responsive rendering beyond show/hide. The width is the
/// actual inner width (container query), not the viewport.
class FwResponsiveBuilder extends StatelessWidget {
  const FwResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    double width,
    FwBreakpoint breakpoint,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError('FwResponsiveBuilder requires bounded width.');
        }
        final width = constraints.maxWidth;
        return builder(context, width, theme.breakpoints.at(width));
      },
    );
  }
}
