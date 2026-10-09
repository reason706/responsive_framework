import 'package:flutter/widgets.dart';

import '../lengths/length.dart';
import '../responsive.dart';

/// Typography roles from the design-system scale.
///
/// Visual size and semantic heading level are independent: a widget may
/// render `h1` sizing while announcing a different heading level, or vice
/// versa. Roles resolve to declared (unscaled) sizes; Flutter's [TextScaler]
/// applies exactly once at render time.
enum FwTextRole {
  displayLg,
  displaySm,
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  lead,
  body,
  bodySm,
  caption,
  label,
  code,
}

/// Font family slots configured on [FwTypography].
enum FwFontRole { body, heading, monospace }

/// Configured font families with fallbacks.
///
/// The framework never requires Google Fonts at runtime. Applications supply
/// their own licensed font assets; the gallery bundles Roboto as an example.
/// [heading] defaults to [body] when unset.
@immutable
class FwFontFamilies {
  const FwFontFamilies({
    this.body = 'Roboto',
    this.heading,
    this.monospace = 'RobotoMono',
    this.fallback = const <String>['sans-serif'],
  });

  final String body;
  final String? heading;
  final String monospace;
  final List<String> fallback;

  String familyFor(FwFontRole role) => switch (role) {
    FwFontRole.body => body,
    FwFontRole.heading => heading ?? body,
    FwFontRole.monospace => monospace,
  };

  FwFontFamilies copyWith({
    String? body,
    String? heading,
    String? monospace,
    List<String>? fallback,
  }) => FwFontFamilies(
    body: body ?? this.body,
    heading: heading ?? this.heading,
    monospace: monospace ?? this.monospace,
    fallback: fallback ?? this.fallback,
  );
}

/// One typography role: size expression, line-height multiplier, weight,
/// tracking, and font slot.
///
/// `size` is any [FwLength]; fluid headings interpolate between rem bounds
/// across the container width. `TextStyle.height` stays a multiplier, never
/// an absolute rem height. Tracking resolves through the same typed unit
/// system as everything else.
@immutable
class FwTextStyle {
  FwTextStyle({
    required this.size,
    this.lineHeight = 1.5,
    this.weight = FontWeight.w400,
    this.tracking,
    this.fontRole = FwFontRole.body,
    this.decoration,
    this.paragraphSpacing,
  }) {
    if (!lineHeight.isFinite || lineHeight <= 0) {
      throw ArgumentError.value(
        lineHeight,
        'lineHeight',
        'Must be a finite positive multiplier.',
      );
    }
  }

  final FwLength size;
  final double lineHeight;
  final FontWeight weight;
  final FwLength? tracking;
  final FwFontRole fontRole;
  final TextDecoration? decoration;

  /// Optional space after a paragraph in this role.
  final FwLength? paragraphSpacing;

  /// Resolves to a Flutter [TextStyle] with the **declared** (unscaled)
  /// font size. The ambient [TextScaler] — linear or nonlinear — applies
  /// exactly once when the text renders. Never pre-scale here.
  TextStyle resolve(BuildContext context, FwFontFamilies fonts) {
    return TextStyle(
      fontSize: size.resolve(context),
      height: lineHeight,
      fontWeight: weight,
      letterSpacing: tracking?.resolve(context),
      fontFamily: fonts.familyFor(fontRole),
      fontFamilyFallback: fonts.fallback,
      decoration: decoration,
    );
  }

  /// Context-free resolution for static snapshots and tests.
  TextStyle resolveRaw({
    required double rootSize,
    required FwFontFamilies fonts,
    double? explicitWidth,
    double? emSize,
  }) {
    return TextStyle(
      fontSize: size.resolveRaw(
        rootSize: rootSize,
        explicitWidth: explicitWidth,
        emSize: emSize,
      ),
      height: lineHeight,
      fontWeight: weight,
      letterSpacing: tracking?.resolveRaw(
        rootSize: rootSize,
        explicitWidth: explicitWidth,
        emSize: emSize,
      ),
      fontFamily: fonts.familyFor(fontRole),
      fontFamilyFallback: fonts.fallback,
      decoration: decoration,
    );
  }
}

/// The framework type scale: one [FwTextStyle] per [FwTextRole].
///
/// Default sizes follow the design-system table at root 16. Headings and
/// display sizes are fluid between 360 and 1200 logical pixels of container
/// width; body and control text stay at fixed rem sizes so narrow layouts
/// remain readable.
///
/// Weight note: the spec table suggests 600 for h2–h6/label, but the bundled
/// example faces (Roboto Regular/Medium/Bold) contain no 600 face. The
/// default preset uses 500 — a supported face — instead of relying on the
/// engine's nearest-weight fallback. Applications with a real 600 face can
/// override per role.
@immutable
class FwTypography {
  FwTypography({required Map<FwTextRole, FwTextStyle> roles, this.fonts})
    : roles = Map.unmodifiable(roles) {
    for (final role in FwTextRole.values) {
      if (!roles.containsKey(role)) {
        throw ArgumentError('FwTypography is missing role $role.');
      }
    }
  }

  /// Default scale per the design-system specification.
  factory FwTypography.defaults() {
    FwTextStyle style({
      required FwLength size,
      double lineHeight = 1.5,
      FontWeight weight = FontWeight.w400,
      FwFontRole fontRole = FwFontRole.body,
    }) => FwTextStyle(
      size: size,
      lineHeight: lineHeight,
      weight: weight,
      fontRole: fontRole,
    );

    FwLength fluid(double minRem, double maxRem) => FwFluid(
      min: FwRem(minRem),
      max: FwRem(maxRem),
      fromWidth: FwPx(360),
      toWidth: FwPx(1200),
    );

    const heading = FwFontRole.heading;
    return FwTypography(
      roles: {
        FwTextRole.displayLg: style(
          size: fluid(2.5, 4),
          lineHeight: 1.1,
          weight: FontWeight.w700,
          fontRole: heading,
        ),
        FwTextRole.displaySm: style(
          size: fluid(2, 3),
          lineHeight: 1.15,
          weight: FontWeight.w700,
          fontRole: heading,
        ),
        FwTextRole.h1: style(
          size: fluid(1.75, 2.5),
          lineHeight: 1.2,
          weight: FontWeight.w700,
          fontRole: heading,
        ),
        FwTextRole.h2: style(
          size: fluid(1.5, 2),
          lineHeight: 1.25,
          weight: FontWeight.w500,
          fontRole: heading,
        ),
        FwTextRole.h3: style(
          size: fluid(1.25, 1.5),
          lineHeight: 1.3,
          weight: FontWeight.w500,
          fontRole: heading,
        ),
        FwTextRole.h4: style(
          size: fluid(1.125, 1.25),
          lineHeight: 1.35,
          weight: FontWeight.w500,
          fontRole: heading,
        ),
        FwTextRole.h5: style(
          size: FwRem(1.0625),
          lineHeight: 1.4,
          weight: FontWeight.w500,
          fontRole: heading,
        ),
        FwTextRole.h6: style(
          size: FwRem(1),
          lineHeight: 1.4,
          weight: FontWeight.w500,
          fontRole: heading,
        ),
        FwTextRole.lead: style(size: fluid(1.125, 1.25), lineHeight: 1.5),
        FwTextRole.body: style(size: FwRem(1), lineHeight: 1.5),
        FwTextRole.bodySm: style(size: FwRem(0.875), lineHeight: 1.5),
        FwTextRole.caption: style(size: FwRem(0.75), lineHeight: 1.4),
        FwTextRole.label: style(
          size: FwRem(0.875),
          lineHeight: 1.4,
          weight: FontWeight.w500,
        ),
        FwTextRole.code: style(
          size: FwRem(0.875),
          lineHeight: 1.5,
          fontRole: FwFontRole.monospace,
        ),
      },
    );
  }

  final Map<FwTextRole, FwTextStyle> roles;
  final FwFontFamilies? fonts;

  FwFontFamilies get effectiveFonts => fonts ?? const FwFontFamilies();

  FwTextStyle of(FwTextRole role) => roles[role]!;

  /// Declared (unscaled) [TextStyle] for [role]; the ambient scaler applies once.
  TextStyle resolve(FwTextRole role, BuildContext context) =>
      of(role).resolve(context, effectiveFonts);

  /// Static Material [TextTheme] snapshot at [rootSize].
  ///
  /// Fluid roles are captured at their minimum endpoint and responsive sizes
  /// at their base value: a static theme cannot track container width.
  /// Framework text widgets resolve fluidly with real context instead.
  TextTheme toMaterialTextTheme({required double rootSize}) {
    final families = effectiveFonts;
    TextStyle snap(FwTextRole role) => of(role).resolveRaw(
      rootSize: rootSize,
      fonts: families,
      explicitWidth: null,
    );
    return TextTheme(
      displayLarge: snap(FwTextRole.displayLg),
      displayMedium: snap(FwTextRole.displaySm),
      displaySmall: snap(FwTextRole.h1),
      headlineLarge: snap(FwTextRole.h2),
      headlineMedium: snap(FwTextRole.h3),
      headlineSmall: snap(FwTextRole.h4),
      titleLarge: snap(FwTextRole.h5),
      titleMedium: snap(FwTextRole.h6),
      titleSmall: snap(FwTextRole.label),
      bodyLarge: snap(FwTextRole.lead),
      bodyMedium: snap(FwTextRole.body),
      bodySmall: snap(FwTextRole.bodySm),
      labelLarge: snap(FwTextRole.label),
      labelMedium: snap(FwTextRole.caption),
      labelSmall: snap(FwTextRole.code),
    );
  }

  FwTypography copyWith({
    Map<FwTextRole, FwTextStyle>? roles,
    FwFontFamilies? fonts,
  }) => FwTypography(
    roles: roles ?? this.roles,
    fonts: fonts ?? this.fonts,
  );
}
