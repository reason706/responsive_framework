/// Typed box decoration and explicit spacing helpers.
library;

export 'src/async.dart';
export 'src/format.dart';

import 'package:flutter/widgets.dart';
import 'package:fw_core/fw_core.dart';

/// Decoration values are token references; padding uses directional insets.
@immutable
class FwStyle {
  const FwStyle({
    this.padding = EdgeInsetsDirectional.zero,
    this.background,
    this.radius = FwRadius.none,
    this.borderColor,
    this.borderWidth = 1,
  }) : assert(borderWidth >= 0);

  final EdgeInsetsGeometry padding;
  final FwColorRole? background;
  final FwRadius radius;
  final FwColorRole? borderColor;
  final double borderWidth;
}

/// Decoration outside padding; does not implicitly clip overflowing content.
class FwBox extends StatelessWidget {
  const FwBox({super.key, required this.child, this.style = const FwStyle()});

  final Widget child;
  final FwStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fwTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background == null
            ? null
            : theme.colors.of(style.background!),
        borderRadius: BorderRadius.circular(theme.radii.of(style.radius)),
        border: style.borderColor == null
            ? null
            : Border.all(
                color: theme.colors.of(style.borderColor!),
                width: style.borderWidth,
              ),
      ),
      child: Padding(padding: style.padding, child: child),
    );
  }
}

extension FwWidgetSpacing on Widget {
  /// Padding in logical pixels, not a token index.
  Widget paddingAll(double pixels) =>
      Padding(padding: EdgeInsets.all(pixels), child: this);

  /// Padding resolved from theme tokens at build time.
  Widget paddingToken(FwSpace token) => Builder(
    builder: (context) => Padding(
      padding: EdgeInsets.all(context.fwTheme.spacing.of(token)),
      child: this,
    ),
  );
}
