import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// Named icon sizes.
///
/// Icons are fixed logical pixels: a 16px icon must not become 18px because
/// the root grew, and density never shrinks iconography. The class below is
/// theme-resolvable so a brand can adopt a different icon grid.
enum FwIconSize { sm, md, lg, xl }

/// Theme-resolvable icon size table.
///
/// Defaults come from `tokens.yaml` (`icon-size.*`); override per theme for
/// a custom icon grid.
@immutable
class FwIconSizes {
  const FwIconSizes({
    this.sm = FwTokenValues.iconSizeSmPx,
    this.md = FwTokenValues.iconSizeMdPx,
    this.lg = FwTokenValues.iconSizeLgPx,
    this.xl = FwTokenValues.iconSizeXlPx,
  });

  /// 16px. Inline with body text.
  final double sm;

  /// 20px. Default: buttons, list tiles.
  final double md;

  /// 24px. Navigation, empty states.
  final double lg;

  /// 32px. Feature highlights.
  final double xl;

  /// Resolves a named icon size to logical pixels (root- and density-free).
  double of(FwIconSize size) => switch (size) {
    FwIconSize.sm => sm,
    FwIconSize.md => md,
    FwIconSize.lg => lg,
    FwIconSize.xl => xl,
  };

  FwIconSizes copyWith({double? sm, double? md, double? lg, double? xl}) =>
      FwIconSizes(
        sm: sm ?? this.sm,
        md: md ?? this.md,
        lg: lg ?? this.lg,
        xl: xl ?? this.xl,
      );
}
