import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// WCAG contrast ratio between [foreground] and [background].
///
/// Use it to validate custom color pairs: normal text needs >= 4.5, large
/// text and non-text indicators >= 3. A palette test never establishes
/// whole-application compliance.
double contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final high = a > b ? a : b;
  final low = a > b ? b : a;
  return (high + 0.05) / (low + 0.05);
}

/// Layer 1 — raw color primitives.
///
/// Every raw hex literal in the token system lives here and only here:
/// brand seeds and the hand-validated status pairs are named constants
/// with no semantic meaning attached. The semantic layer ([FwColors]) maps
/// roles onto these values; components must never reference primitives
/// directly — they resolve [FwColorRole]s (or component tokens built from
/// them). A repository test (`no_raw_color_test.dart`) fails the build if
/// a `Color(0x…)` literal appears anywhere under `lib/` outside `src/tokens/`.
///
/// Naming discipline (from the 2025–2026 token research): a brand name never
/// appears in a *token key*. These `*Seed` constants are theme-axis *inputs*,
/// not token keys — the same semantic keys resolve to different values per
/// brand preset.
///
/// Values are generated from tokens.yaml ([FwTokenValues]); this class is
/// the hand-curated, documented view over them.
abstract final class FwColorPrimitives {
  /// Default brand seed (Material baseline purple).
  static const Color defaultSeed = FwTokenValues.colorSeedDefault;

  /// Ocean brand seed.
  static const Color oceanSeed = FwTokenValues.colorSeedOcean;

  /// Forest brand seed.
  static const Color forestSeed = FwTokenValues.colorSeedForest;

  /// Sunset brand seed.
  static const Color sunsetSeed = FwTokenValues.colorSeedSunset;

  /// Monochrome brand seed; `ColorScheme.fromSeed` derives the gray ramp.
  static const Color monochromeSeed = FwTokenValues.colorSeedMonochrome;

  // Status primitives: fixed, brightness-aware pairs. A seed cannot
  // meaningfully generate status colors, so these stay hand-validated
  // (every pair >= 4.5:1, verified in colors_test.dart).
  static const Color successLight = FwTokenValues.colorStatusSuccessLight;
  static const Color onSuccessLight = FwTokenValues.colorStatusSuccessOnLight;
  static const Color successContainerLight =
      FwTokenValues.colorStatusSuccessContainerLight;
  static const Color onSuccessContainerLight =
      FwTokenValues.colorStatusSuccessOnContainerLight;
  static const Color warningLight = FwTokenValues.colorStatusWarningLight;
  static const Color onWarningLight = FwTokenValues.colorStatusWarningOnLight;
  static const Color warningContainerLight =
      FwTokenValues.colorStatusWarningContainerLight;
  static const Color onWarningContainerLight =
      FwTokenValues.colorStatusWarningOnContainerLight;
  static const Color infoLight = FwTokenValues.colorStatusInfoLight;
  static const Color onInfoLight = FwTokenValues.colorStatusInfoOnLight;
  static const Color infoContainerLight =
      FwTokenValues.colorStatusInfoContainerLight;
  static const Color onInfoContainerLight =
      FwTokenValues.colorStatusInfoOnContainerLight;
  static const Color successDark = FwTokenValues.colorStatusSuccessDark;
  static const Color onSuccessDark = FwTokenValues.colorStatusSuccessOnDark;
  static const Color successContainerDark =
      FwTokenValues.colorStatusSuccessContainerDark;
  static const Color onSuccessContainerDark =
      FwTokenValues.colorStatusSuccessOnContainerDark;
  static const Color warningDark = FwTokenValues.colorStatusWarningDark;
  static const Color onWarningDark = FwTokenValues.colorStatusWarningOnDark;
  static const Color warningContainerDark =
      FwTokenValues.colorStatusWarningContainerDark;
  static const Color onWarningContainerDark =
      FwTokenValues.colorStatusWarningOnContainerDark;
  static const Color infoDark = FwTokenValues.colorStatusInfoDark;
  static const Color onInfoDark = FwTokenValues.colorStatusInfoOnDark;
  static const Color infoContainerDark =
      FwTokenValues.colorStatusInfoContainerDark;
  static const Color onInfoContainerDark =
      FwTokenValues.colorStatusInfoOnContainerDark;
}

/// Every semantic color role. Components reference these roles, never raw
/// palette numbers, so a brand/mode change updates all of them consistently.
///
/// "Danger" is the semantic name for the [error]/[onError] roles, which
/// stay Material-mapped for compatibility.
enum FwColorRole {
  // Brand.
  primary,
  onPrimary,
  primaryContainer,
  onPrimaryContainer,
  secondary,
  onSecondary,
  secondaryContainer,
  onSecondaryContainer,
  // Surfaces.
  background,
  onBackground,
  surface,
  onSurface,
  surfaceContainerLowest,
  surfaceContainerLow,
  surfaceContainer,
  surfaceContainerHigh,
  surfaceContainerHighest,
  surfaceMuted,
  onSurfaceMuted,
  // Text.
  text,
  textMuted,
  textSubtle,
  // Status.
  success,
  onSuccess,
  successContainer,
  onSuccessContainer,
  warning,
  onWarning,
  warningContainer,
  onWarningContainer,
  info,
  onInfo,
  infoContainer,
  onInfoContainer,
  error,
  onError,
  errorContainer,
  onErrorContainer,
  // Borders and focus.
  border,
  borderStrong,
  focusRing,
  // Interaction.
  selection,
  scrim,
  disabled,
  onDisabled,
  // Inverse.
  inverseSurface,
  onInverseSurface,
  inversePrimary,
  // Legacy Material outline.
  outline,
}

/// Semantic colors: a Material [ColorScheme] base plus explicitly generated
/// and contrast-validated status pairs.
///
/// `ColorScheme.fromSeed` supplies the Material-mapped roles; status colors
/// (success/warning/info) are fixed, brightness-aware values — not derived
/// from the seed — because a seed cannot meaningfully generate them. Every
/// shipped pair is covered by contrast tests; arbitrary overrides need
/// their own validation.
@immutable
class FwColors {
  FwColors._({
    required this.scheme,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Builds semantic colors from a Material scheme, selecting the status
  /// pairs validated for the scheme's brightness.
  ///
  /// Layer 2 — semantic roles: every raw value comes from
  /// [FwColorPrimitives]; this class only decides *which* primitive a role
  /// maps to. Components resolve [FwColorRole]s (layer 2) or component
  /// tokens built from them (layer 3), never primitives.
  factory FwColors(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return FwColors._(
      scheme: scheme,
      success: dark
          ? FwColorPrimitives.successDark
          : FwColorPrimitives.successLight,
      onSuccess: dark
          ? FwColorPrimitives.onSuccessDark
          : FwColorPrimitives.onSuccessLight,
      successContainer: dark
          ? FwColorPrimitives.successContainerDark
          : FwColorPrimitives.successContainerLight,
      onSuccessContainer: dark
          ? FwColorPrimitives.onSuccessContainerDark
          : FwColorPrimitives.onSuccessContainerLight,
      warning: dark
          ? FwColorPrimitives.warningDark
          : FwColorPrimitives.warningLight,
      onWarning: dark
          ? FwColorPrimitives.onWarningDark
          : FwColorPrimitives.onWarningLight,
      warningContainer: dark
          ? FwColorPrimitives.warningContainerDark
          : FwColorPrimitives.warningContainerLight,
      onWarningContainer: dark
          ? FwColorPrimitives.onWarningContainerDark
          : FwColorPrimitives.onWarningContainerLight,
      info: dark ? FwColorPrimitives.infoDark : FwColorPrimitives.infoLight,
      onInfo: dark
          ? FwColorPrimitives.onInfoDark
          : FwColorPrimitives.onInfoLight,
      infoContainer: dark
          ? FwColorPrimitives.infoContainerDark
          : FwColorPrimitives.infoContainerLight,
      onInfoContainer: dark
          ? FwColorPrimitives.onInfoContainerDark
          : FwColorPrimitives.onInfoContainerLight,
    );
  }

  final ColorScheme scheme;

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Resolves a semantic role to a concrete color.
  Color of(FwColorRole role) => switch (role) {
    FwColorRole.primary => scheme.primary,
    FwColorRole.onPrimary => scheme.onPrimary,
    FwColorRole.primaryContainer => scheme.primaryContainer,
    FwColorRole.onPrimaryContainer => scheme.onPrimaryContainer,
    FwColorRole.secondary => scheme.secondary,
    FwColorRole.onSecondary => scheme.onSecondary,
    FwColorRole.secondaryContainer => scheme.secondaryContainer,
    FwColorRole.onSecondaryContainer => scheme.onSecondaryContainer,
    FwColorRole.background => scheme.surface,
    FwColorRole.onBackground => scheme.onSurface,
    FwColorRole.surface => scheme.surface,
    FwColorRole.onSurface => scheme.onSurface,
    FwColorRole.surfaceContainerLowest => scheme.surfaceContainerLowest,
    FwColorRole.surfaceContainerLow => scheme.surfaceContainerLow,
    FwColorRole.surfaceContainer => scheme.surfaceContainer,
    FwColorRole.surfaceContainerHigh => scheme.surfaceContainerHigh,
    FwColorRole.surfaceContainerHighest => scheme.surfaceContainerHighest,
    FwColorRole.surfaceMuted => scheme.surfaceContainerLow,
    FwColorRole.onSurfaceMuted => scheme.onSurfaceVariant,
    FwColorRole.text => scheme.onSurface,
    FwColorRole.textMuted => scheme.onSurfaceVariant,
    // Secondary annotations only — never the default for critical
    // instructions, which must meet text contrast.
    FwColorRole.textSubtle => scheme.outline,
    FwColorRole.success => success,
    FwColorRole.onSuccess => onSuccess,
    FwColorRole.successContainer => successContainer,
    FwColorRole.onSuccessContainer => onSuccessContainer,
    FwColorRole.warning => warning,
    FwColorRole.onWarning => onWarning,
    FwColorRole.warningContainer => warningContainer,
    FwColorRole.onWarningContainer => onWarningContainer,
    FwColorRole.info => info,
    FwColorRole.onInfo => onInfo,
    FwColorRole.infoContainer => infoContainer,
    FwColorRole.onInfoContainer => onInfoContainer,
    FwColorRole.error => scheme.error,
    FwColorRole.onError => scheme.onError,
    FwColorRole.errorContainer => scheme.errorContainer,
    FwColorRole.onErrorContainer => scheme.onErrorContainer,
    FwColorRole.border => scheme.outlineVariant,
    FwColorRole.borderStrong => scheme.outline,
    // Must remain visible against both its control and surroundings;
    // validated against surfaces for the shipped seeds.
    FwColorRole.focusRing => scheme.primary,
    FwColorRole.selection => scheme.primaryContainer,
    FwColorRole.scrim => scheme.scrim,
    FwColorRole.disabled => scheme.onSurface.withValues(alpha: 0.12),
    FwColorRole.onDisabled => scheme.onSurface.withValues(alpha: 0.38),
    FwColorRole.inverseSurface => scheme.inverseSurface,
    FwColorRole.onInverseSurface => scheme.onInverseSurface,
    FwColorRole.inversePrimary => scheme.inversePrimary,
    FwColorRole.outline => scheme.outline,
  };

  FwColors copyWith({
    ColorScheme? scheme,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) => FwColors._(
    scheme: scheme ?? this.scheme,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
  );

  /// Interpolates the scheme and every status color.
  FwColors lerp(FwColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FwColors._(
      scheme: ColorScheme.lerp(scheme, other.scheme, t),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      onWarningContainer: mix(onWarningContainer, other.onWarningContainer),
      info: mix(info, other.info),
      onInfo: mix(onInfo, other.onInfo),
      infoContainer: mix(infoContainer, other.infoContainer),
      onInfoContainer: mix(onInfoContainer, other.onInfoContainer),
    );
  }
}

/// Shared typed component-state vocabulary, aligned with [WidgetState].
///
/// Resolve a color role for a set of states with documented precedence:
///
/// ```text
/// disabled > pressed > hovered > selected > invalid > focused > base
/// ```
///
/// Disabled always wins — a disabled control never looks activatable.
/// Invalid and focused coexist: invalid selects the color while focus keeps
/// its ring, which is drawn separately and never conveyed by color alone.
/// Busy is handled by components (it disables activation); it is not a
/// [WidgetState].
@immutable
class FwStateRoles {
  const FwStateRoles({
    this.base,
    this.hovered,
    this.pressed,
    this.focused,
    this.selected,
    this.disabled,
    this.invalid,
  });

  final FwColorRole? base;
  final FwColorRole? hovered;
  final FwColorRole? pressed;
  final FwColorRole? focused;
  final FwColorRole? selected;
  final FwColorRole? disabled;
  final FwColorRole? invalid;

  /// The winning role for [states], or null when no role is configured.
  FwColorRole? roleFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled) && disabled != null) {
      return disabled;
    }
    if (states.contains(WidgetState.pressed) && pressed != null) {
      return pressed;
    }
    if (states.contains(WidgetState.hovered) && hovered != null) {
      return hovered;
    }
    if (states.contains(WidgetState.selected) && selected != null) {
      return selected;
    }
    if (states.contains(WidgetState.error) && invalid != null) {
      return invalid;
    }
    if (states.contains(WidgetState.focused) && focused != null) {
      return focused;
    }
    return base;
  }

  /// Resolves the winning role against [colors], or null when unconfigured.
  Color? resolve(Set<WidgetState> states, FwColors colors) {
    final role = roleFor(states);
    return role == null ? null : colors.of(role);
  }
}
