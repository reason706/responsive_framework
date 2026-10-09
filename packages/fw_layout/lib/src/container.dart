import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// Centers content using Bootstrap-style maximum widths and token padding.
///
/// Thresholds use the available parent width. Padding is inside the maximum
/// width. Grid children subsequently measure the remaining content width.
class FwContainer extends StatelessWidget {
  const FwContainer({
    super.key,
    required this.child,
    this.padding = FwSpace.s4,
    this.fluid = false,
    this.maxWidth = const Responsive<double>(
      base: double.infinity,
      sm: 540,
      md: 720,
      lg: 960,
      xl: 1140,
      xxl: 1320,
    ),
  });

  final Widget child;
  final FwSpace padding;
  final bool fluid;
  final Responsive<double> maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'FwContainer requires bounded horizontal constraints.',
          );
        }
        final limit = fluid
            ? constraints.maxWidth
            : maxWidth.resolve(theme.breakpoints.at(constraints.maxWidth));
        if (limit.isNaN || limit < 0) {
          throw ArgumentError.value(limit, 'maxWidth', 'Must be nonnegative.');
        }
        return Align(
          alignment: AlignmentDirectional.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: limit),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: theme.spaceScale.of(padding, context),
                ),
                child: FwContainerQuery(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
