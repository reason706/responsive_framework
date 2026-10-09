import 'package:flutter/widgets.dart';

import '../lengths/length.dart';

/// Typed border widths with explicit pixel vs rem roles.
///
/// Hairlines and thin borders stay in logical pixels: a 1px divider must
/// not become thick just because the root grows. Structural emphasis
/// borders may use rem so they scale with the design.
@immutable
class FwBorders {
  FwBorders({FwLength? hairline, FwLength? thin, FwLength? medium})
    : hairline = hairline ?? FwPx(1),
      thin = thin ?? FwPx(2),
      medium = medium ?? FwRem(0.25);

  /// 1 logical pixel. For dividers and hairline outlines.
  final FwLength hairline;

  /// 2 logical pixels. For emphasized outlines.
  final FwLength thin;

  /// 0.25rem. Root-relative structural borders.
  final FwLength medium;

  double resolveHairline(BuildContext context) => hairline.resolve(context);
  double resolveThin(BuildContext context) => thin.resolve(context);
  double resolveMedium(BuildContext context) => medium.resolve(context);

  FwBorders copyWith({FwLength? hairline, FwLength? thin, FwLength? medium}) =>
      FwBorders(
        hairline: hairline ?? this.hairline,
        thin: thin ?? this.thin,
        medium: medium ?? this.medium,
      );
}
