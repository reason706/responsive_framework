import 'package:flutter/material.dart';

/// Elevation levels with color-mode-specific shadow colors.
///
/// Shadows are decorative depth cues, never the only indicator of state.
/// Each preset ships light and dark variants; custom themes should keep
/// shadow colors subtle against their surfaces.
@immutable
class FwShadows {
  const FwShadows({
    this.none = const <BoxShadow>[],
    this.sm = const <BoxShadow>[
      BoxShadow(color: Color(0x1F000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    this.md = const <BoxShadow>[
      BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
    this.lg = const <BoxShadow>[
      BoxShadow(
        color: Color(0x2E000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  });

  /// Dark-mode variant with softer, more transparent shadows.
  const FwShadows.dark({
    this.none = const <BoxShadow>[],
    this.sm = const <BoxShadow>[
      BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    this.md = const <BoxShadow>[
      BoxShadow(color: Color(0x3D000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
    this.lg = const <BoxShadow>[
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ],
  });

  final List<BoxShadow> none;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;

  /// Interpolates each level pairwise; levels with different lengths switch
  /// discretely at t = 0.5.
  FwShadows lerp(FwShadows? other, double t) {
    if (other == null) return this;
    List<BoxShadow> level(List<BoxShadow> a, List<BoxShadow> b) {
      if (a.length != b.length) return t < 0.5 ? a : b;
      return [
        for (var i = 0; i < a.length; i++) BoxShadow.lerp(a[i], b[i], t)!,
      ];
    }

    return FwShadows(
      none: level(none, other.none),
      sm: level(sm, other.sm),
      md: level(md, other.md),
      lg: level(lg, other.lg),
    );
  }
}
