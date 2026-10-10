import 'package:flutter/material.dart';

import '../theme.dart';
import 'colors.dart';
import 'shadows.dart';
import 'tokens.g.dart';

/// Elevation levels 0–5: surface tint + shadow tokens.
///
/// Overlays, dialogs, menus, and raised surfaces consume these levels;
/// they never construct raw [BoxShadow]s (a repository test enforces this).
/// The tint follows the Material surface-tint model — the primary color at
/// an increasing alpha — while the shadows come from [FwShadows], so light
/// and dark modes keep their own shadow colors.
///
/// Stance (improvement-plan-2 P3.1): this framework adopts the **Material 3**
/// elevation model — tonal surface tint *plus* shadow — over Carbon's
/// no-shadow stance (depth via surface-color layering and hairlines).
/// Either stance is valid; mixing them is not. Consumers that want the
/// flatter look pass `tonal: false` (shadow only) or level 0.
@immutable
class FwElevation {
  const FwElevation();

  static const int minLevel = 0;
  static const int maxLevel = 5;

  /// Surface-tint alphas per level, M3-inspired. Generated from tokens.yaml.
  static const List<double> tintAlphas = [
    FwTokenValues.elevationTintAlphaLevel0,
    FwTokenValues.elevationTintAlphaLevel1,
    FwTokenValues.elevationTintAlphaLevel2,
    FwTokenValues.elevationTintAlphaLevel3,
    FwTokenValues.elevationTintAlphaLevel4,
    FwTokenValues.elevationTintAlphaLevel5,
  ];

  /// Resolves [level] against the ambient theme. Throws [RangeError] for
  /// levels outside 0–5.
  FwElevationLevel of(BuildContext context, int level) {
    RangeError.checkValueInInterval(level, minLevel, maxLevel, 'level');
    final theme = context.fwTheme;
    return FwElevationLevel._(
      level: level,
      surfaceTint: theme.colors
          .of(FwColorRole.primary)
          .withValues(alpha: tintAlphas[level]),
      shadows: _shadowsFor(theme.shadows, level),
    );
  }

  /// The [BoxDecoration] for a raised surface at [level].
  ///
  /// [tonal] blends the M3 surface tint over [color] (default: the surface
  /// color). Pass false for shadow-only depth (the flatter,
  /// Carbon-adjacent look). Components that fill with a container color
  /// pass it as [color] so the tint applies over their fill.
  BoxDecoration decoration(
    BuildContext context,
    int level, {
    bool tonal = true,
    Color? color,
  }) {
    final resolved = of(context, level);
    final base = color ?? context.fwTheme.colors.of(FwColorRole.surface);
    return BoxDecoration(
      color: tonal ? Color.alphaBlend(resolved.surfaceTint, base) : base,
      boxShadow: resolved.shadows,
    );
  }

  static List<BoxShadow> _shadowsFor(FwShadows shadows, int level) =>
      switch (level) {
        0 => shadows.none,
        1 => shadows.sm,
        2 || 3 => shadows.md,
        _ => shadows.lg,
      };
}

/// One resolved elevation level: its tint color and shadow list.
@immutable
class FwElevationLevel {
  const FwElevationLevel._({
    required this.level,
    required this.surfaceTint,
    required this.shadows,
  });

  final int level;
  final Color surfaceTint;
  final List<BoxShadow> shadows;
}
