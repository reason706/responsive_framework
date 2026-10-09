import 'package:flutter/material.dart';

import 'metrics/metrics.dart';
import 'responsive.dart';
import 'theme/component_colors.dart';
import 'tokens/borders.dart';
import 'tokens/colors.dart';
import 'tokens/motion.dart';
import 'tokens/shadows.dart';
import 'tokens/spacing.dart';
import 'typography/typography.dart';

@immutable
class FwSpacing {
  const FwSpacing({this.unit = 4}) : assert(unit >= 0);

  final double unit;

  double of(FwSpace token) =>
      const [0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 24][token.index] * unit;
}

enum FwRadius { none, sm, md, lg, xl, pill }

@immutable
class FwRadii {
  const FwRadii({this.sm = 4, this.md = 8, this.lg = 12, this.xl = 16});

  final double sm;
  final double md;
  final double lg;
  final double xl;

  double of(FwRadius radius) => switch (radius) {
    FwRadius.none => 0,
    FwRadius.sm => sm,
    FwRadius.md => md,
    FwRadius.lg => lg,
    FwRadius.xl => xl,
    FwRadius.pill => 999,
  };
}

/// Shared tokens. Structural breakpoint changes are discrete during animation.
///
/// The constructor is intentionally not const: [typeScale] defaults to the
/// framework type scale, whose fluid lengths require validated factories.
class FwTheme extends ThemeExtension<FwTheme> {
  FwTheme({
    required this.colors,
    TextTheme? typography,
    FwTypography? typeScale,
    this.spacing = const FwSpacing(),
    this.radii = const FwRadii(),
    this.breakpoints = FwBreakpoints.standard,
    this.metrics = const FwMetrics(),
    FwBorders? borders,
    FwShadows? shadows,
    this.motion = const FwMotion(),
    FwButtonColors? buttonColors,
    this.minTapTarget = 48,
    this.focusWidth = 2,
  }) : typeScale = typeScale ?? FwTypography.defaults(),
       typography =
           typography ??
           (typeScale ?? FwTypography.defaults()).toMaterialTextTheme(
             rootSize: metrics.rootSize,
           ),
       borders = borders ?? FwBorders(),
       shadows = shadows ?? const FwShadows(),
       buttonColors = buttonColors ?? FwButtonColors.fromColors(colors),
       assert(minTapTarget >= 48),
       assert(focusWidth > 0);

  factory FwTheme.light({
    Color seed = FwColorPrimitives.defaultSeed,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: seed,
    brightness: Brightness.light,
    metrics: FwMetrics(density: density),
  );

  factory FwTheme.dark({
    Color seed = FwColorPrimitives.defaultSeed,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: seed,
    brightness: Brightness.dark,
    metrics: FwMetrics(density: density),
  );

  /// High-contrast light preset for low-vision users. Text pairs target 7:1.
  factory FwTheme.highContrastLight() =>
      FwTheme(colors: FwColors(const ColorScheme.highContrastLight()));

  /// High-contrast dark preset for low-vision users. Text pairs target 7:1.
  factory FwTheme.highContrastDark() => FwTheme(
    colors: FwColors(const ColorScheme.highContrastDark()),
    shadows: const FwShadows.dark(),
  );

  /// Named brand presets: Ocean, Forest, Sunset, Monochrome.
  ///
  /// Light/dark policy: every brand is a pinned seed from
  /// [FwColorPrimitives] plus a [brightness]. Light and dark are
  /// value-swaps on identical token keys — the same [FwColorRole] set
  /// resolves to different values, so components never branch on the
  /// brand. High contrast stays a separate cross-brand policy
  /// ([highContrastLight]/[highContrastDark]) rather than a per-brand
  /// variant, because its 7:1 text targets need fixed schemes, not
  /// seed-derived ones.
  ///
  /// Each preset's text roles are validated at >= 4.5:1 in
  /// `presets_test.dart`.
  factory FwTheme.ocean({
    Brightness brightness = Brightness.light,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: FwColorPrimitives.oceanSeed,
    brightness: brightness,
    metrics: FwMetrics(density: density),
  );

  /// Forest brand preset. See [ocean] for the light/dark policy.
  factory FwTheme.forest({
    Brightness brightness = Brightness.light,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: FwColorPrimitives.forestSeed,
    brightness: brightness,
    metrics: FwMetrics(density: density),
  );

  /// Sunset brand preset. See [ocean] for the light/dark policy.
  factory FwTheme.sunset({
    Brightness brightness = Brightness.light,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: FwColorPrimitives.sunsetSeed,
    brightness: brightness,
    metrics: FwMetrics(density: density),
  );

  /// Monochrome brand preset: a gray seed produces a full tonal gray
  /// scheme. See [ocean] for the light/dark policy.
  factory FwTheme.monochrome({
    Brightness brightness = Brightness.light,
    FwDensity density = FwDensity.comfortable,
  }) => FwTheme.fromSeed(
    seed: FwColorPrimitives.monochromeSeed,
    brightness: brightness,
    metrics: FwMetrics(density: density),
  );

  /// Every shipped preset, for the preset gallery and audits.
  static List<({String name, FwTheme theme})> get presets => [
    (name: 'Light', theme: FwTheme.light()),
    (name: 'Dark', theme: FwTheme.dark()),
    (name: 'Light · High contrast', theme: FwTheme.highContrastLight()),
    (name: 'Dark · High contrast', theme: FwTheme.highContrastDark()),
    (name: 'Light · Compact', theme: FwTheme.light(density: FwDensity.compact)),
    (
      name: 'Light · Comfortable',
      theme: FwTheme.light(density: FwDensity.comfortable),
    ),
    (name: 'Ocean', theme: FwTheme.ocean()),
    (name: 'Ocean · Dark', theme: FwTheme.ocean(brightness: Brightness.dark)),
    (name: 'Forest', theme: FwTheme.forest()),
    (name: 'Forest · Dark', theme: FwTheme.forest(brightness: Brightness.dark)),
    (name: 'Sunset', theme: FwTheme.sunset()),
    (name: 'Sunset · Dark', theme: FwTheme.sunset(brightness: Brightness.dark)),
    (name: 'Monochrome', theme: FwTheme.monochrome()),
    (
      name: 'Monochrome · Dark',
      theme: FwTheme.monochrome(brightness: Brightness.dark),
    ),
  ];

  factory FwTheme.fromSeed({
    required Color seed,
    required Brightness brightness,
    FwMetrics metrics = const FwMetrics(),
    FwTypography? typeScale,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return FwTheme(
      colors: FwColors(scheme),
      typeScale: typeScale,
      metrics: metrics,
      shadows: brightness == Brightness.light
          ? const FwShadows()
          : const FwShadows.dark(),
    );
  }

  final FwColors colors;

  /// Material text theme mapped from [typeScale].
  ///
  /// This is a static snapshot: fluid roles are captured at their minimum
  /// endpoint and responsive sizes at base. Framework text resolves fluidly
  /// with real context; this mapping keeps native Material primitives on
  /// the same scale. Prefer [typeScale] for new code.
  final TextTheme typography;

  /// Framework type scale: roles, fluid sizes, fonts, tracking.
  final FwTypography typeScale;

  final FwSpacing spacing;

  /// Root-relative spacing scale honoring the ambient root metrics and
  /// density. Prefer this over [spacing] in components: tokens resolve
  /// against the root instead of fixed pixels.
  FwSpaceScale get spaceScale => const FwSpaceScale();
  final FwRadii radii;
  final FwBreakpoints breakpoints;

  /// Root design metrics (root size, density). Used as the fallback when no
  /// explicit [FwRootScope] is present. Nested color scopes inherit the
  /// root; they never redefine it.
  final FwMetrics metrics;

  /// Typed border widths: pixel hairlines vs root-relative structural widths.
  final FwBorders borders;

  /// Elevation levels with color-mode-specific shadow colors.
  final FwShadows shadows;

  /// Durations, curves, and the reduced-motion policy.
  final FwMotion motion;

  /// Layer-3 component color tokens. Defaults to the table derived from
  /// [colors]; override to re-brand a single component family. Registered
  /// in [toThemeData] so components can read it as a [ThemeExtension].
  final FwButtonColors buttonColors;

  final double minTapTarget;
  final double focusWidth;

  static FwTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<FwTheme>();
    if (theme == null) {
      throw FlutterError(
        'FwTheme is missing. Use FwTheme.light().toThemeData() or register '
        'FwTheme in ThemeData.extensions.',
      );
    }
    return theme;
  }

  /// Maps framework roles into Material so native primitives share the theme.
  ///
  /// Component token extensions ([buttonColors]) are registered alongside
  /// the theme so widgets can resolve them with a semantic-role fallback.
  ThemeData toThemeData() => ThemeData(
    useMaterial3: true,
    colorScheme: colors.scheme,
    textTheme: typography,
    extensions: [this, buttonColors],
  );

  @override
  FwTheme copyWith({
    FwColors? colors,
    TextTheme? typography,
    FwTypography? typeScale,
    FwSpacing? spacing,
    FwRadii? radii,
    FwBreakpoints? breakpoints,
    FwMetrics? metrics,
    FwBorders? borders,
    FwShadows? shadows,
    FwMotion? motion,
    FwButtonColors? buttonColors,
    double? minTapTarget,
    double? focusWidth,
  }) {
    final effectiveScale = typeScale ?? this.typeScale;
    final effectiveMetrics = metrics ?? this.metrics;
    // Rebuild the Material snapshot when its inputs change; an explicitly
    // passed typography always wins.
    final scaleChanged =
        !identical(effectiveScale, this.typeScale) ||
        !identical(effectiveMetrics, this.metrics);
    final effectiveColors = colors ?? this.colors;
    return FwTheme(
      colors: effectiveColors,
      typography:
          typography ??
          (scaleChanged
              ? effectiveScale.toMaterialTextTheme(
                  rootSize: effectiveMetrics.rootSize,
                )
              : this.typography),
      typeScale: effectiveScale,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      breakpoints: breakpoints ?? this.breakpoints,
      metrics: effectiveMetrics,
      borders: borders ?? this.borders,
      shadows: shadows ?? this.shadows,
      motion: motion ?? this.motion,
      // A new color set rebuilds the component table unless the caller
      // supplied one explicitly.
      buttonColors:
          buttonColors ??
          (colors == null
              ? this.buttonColors
              : FwButtonColors.fromColors(effectiveColors)),
      minTapTarget: minTapTarget ?? this.minTapTarget,
      focusWidth: focusWidth ?? this.focusWidth,
    );
  }

  @override
  FwTheme lerp(covariant FwTheme? other, double t) {
    if (other == null) return this;
    double mix(double a, double b) => a + (b - a) * t;
    return FwTheme(
      colors: colors.lerp(other.colors, t),
      // The Material snapshot follows the lerped type scale.
      typography: null,
      typeScale: t < 0.5 ? typeScale : other.typeScale,
      spacing: FwSpacing(unit: mix(spacing.unit, other.spacing.unit)),
      radii: FwRadii(
        sm: mix(radii.sm, other.radii.sm),
        md: mix(radii.md, other.radii.md),
        lg: mix(radii.lg, other.radii.lg),
        xl: mix(radii.xl, other.radii.xl),
      ),
      breakpoints: t < 0.5 ? breakpoints : other.breakpoints,
      // Root metrics and density switch discretely like breakpoints.
      metrics: t < 0.5 ? metrics : other.metrics,
      // Border widths are structural: switch discretely.
      borders: t < 0.5 ? borders : other.borders,
      shadows: shadows.lerp(other.shadows, t),
      // Motion durations switch discretely; never animate the policy itself.
      motion: t < 0.5 ? motion : other.motion,
      buttonColors: buttonColors.lerp(other.buttonColors, t),
      minTapTarget: mix(minTapTarget, other.minTapTarget),
      focusWidth: mix(focusWidth, other.focusWidth),
    );
  }
}

extension FwThemeContext on BuildContext {
  FwTheme get fwTheme => FwTheme.of(this);
}
