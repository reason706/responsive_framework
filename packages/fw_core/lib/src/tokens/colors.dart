import 'package:flutter/material.dart';

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
  factory FwColors(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return FwColors._(
      scheme: scheme,
      success: dark ? _successDark : _successLight,
      onSuccess: dark ? _onSuccessDark : _onSuccessLight,
      successContainer: dark ? _successContainerDark : _successContainerLight,
      onSuccessContainer: dark
          ? _onSuccessContainerDark
          : _onSuccessContainerLight,
      warning: dark ? _warningDark : _warningLight,
      onWarning: dark ? _onWarningDark : _onWarningLight,
      warningContainer: dark ? _warningContainerDark : _warningContainerLight,
      onWarningContainer: dark
          ? _onWarningContainerDark
          : _onWarningContainerLight,
      info: dark ? _infoDark : _infoLight,
      onInfo: dark ? _onInfoDark : _onInfoLight,
      infoContainer: dark ? _infoContainerDark : _infoContainerLight,
      onInfoContainer: dark ? _onInfoContainerDark : _onInfoContainerLight,
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

  // Validated status pairs (contrast >= 4.5, verified in colors_test.dart).
  static const _successLight = Color(0xFF2E7D32);
  static const _onSuccessLight = Color(0xFFFFFFFF);
  static const _successContainerLight = Color(0xFFD3E9D5);
  static const _onSuccessContainerLight = Color(0xFF123E1B);
  static const _warningLight = Color(0xFF9C5C00);
  static const _onWarningLight = Color(0xFFFFFFFF);
  static const _warningContainerLight = Color(0xFFF5E0B8);
  static const _onWarningContainerLight = Color(0xFF4A2E00);
  static const _infoLight = Color(0xFF0B6BCB);
  static const _onInfoLight = Color(0xFFFFFFFF);
  static const _infoContainerLight = Color(0xFFD4E4FA);
  static const _onInfoContainerLight = Color(0xFF0A2F5C);
  static const _successDark = Color(0xFF8FD49B);
  static const _onSuccessDark = Color(0xFF0E3B1A);
  static const _successContainerDark = Color(0xFF1E4A26);
  static const _onSuccessContainerDark = Color(0xFFC9E9CE);
  static const _warningDark = Color(0xFFE8B93E);
  static const _onWarningDark = Color(0xFF3A2800);
  static const _warningContainerDark = Color(0xFF4A3500);
  static const _onWarningContainerDark = Color(0xFFF2DFAE);
  static const _infoDark = Color(0xFF7FB3F0);
  static const _onInfoDark = Color(0xFF0A2F5C);
  static const _infoContainerDark = Color(0xFF16395E);
  static const _onInfoContainerDark = Color(0xFFD4E4FA);

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
