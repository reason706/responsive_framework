import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// Column metadata consumed by [FwRow], not a standalone layout widget.
@immutable
class FwCol {
  const FwCol({
    required this.child,
    this.span = const Responsive.all(12),
    this.key,
  });

  final Widget child;
  final Responsive<int> span;
  final Key? key;
}

/// Wrapping twelve-column grid responding to its own available width.
///
/// For width W and gap g, a column is (W - 11g) / 12. A span includes
/// its internal gutters. External gutters are inserted by Wrap. At very narrow
/// widths, the effective gutter shrinks to W / 11 to avoid negative cells.
/// Children remain in source order in both LTR and RTL.
class FwRow extends StatelessWidget {
  const FwRow({
    super.key,
    required this.children,
    this.gap = FwSpace.s4,
    this.runGap = FwSpace.s4,
    this.alignment = WrapAlignment.start,
  });

  final List<FwCol> children;
  final FwSpace gap;
  final FwSpace runGap;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    for (final child in children) {
      for (final breakpoint in FwBreakpoint.values) {
        final span = child.span.resolve(breakpoint);
        if (span < 1 || span > 12) {
          throw ArgumentError.value(span, 'span', 'Must be between 1 and 12.');
        }
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'FwRow requires bounded width. Put it inside a SizedBox or Expanded.',
          );
        }
        final width = constraints.maxWidth;
        final breakpoint = theme.breakpoints.at(width);
        final gutter = math.min(theme.spacing.of(gap), width / 11);
        final columnWidth = math.max(0.0, (width - 11 * gutter) / 12);
        return FwResponsiveScope(
          width: width,
          child: Wrap(
            spacing: gutter,
            runSpacing: theme.spacing.of(runGap),
            alignment: alignment,
            children: [
              for (final col in children)
                SizedBox(
                  key: col.key,
                  width: math.min(
                    width,
                    col.span.resolve(breakpoint) * columnWidth +
                        (col.span.resolve(breakpoint) - 1) * gutter,
                  ),
                  child: col.child,
                ),
            ],
          ),
        );
      },
    );
  }
}
