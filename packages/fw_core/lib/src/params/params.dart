/// Shared component parameter vocabulary and the framework prop taxonomy.
///
/// ## The prop taxonomy (10 groups)
///
/// Every framework component takes its props from these groups, in this
/// order. Groups 1–6 are constructor parameters; groups 7–9 are `*Style`
/// theme-extension classes resolved as `variant × intent × size × state`;
/// group 10 is the escape hatch.
///
/// 1. **Content & identity** — `label`/`child` slots, `leading`/`trailing`
///    widget slots, `icon` + [FwIconPosition], `semanticLabel`.
/// 2. **Visual treatment** — orthogonal enums: `variant` (component-specific),
///    [FwIntent], [FwSize], [FwShape], [FwDensity], `elevationLevel` (0–5 via
///    `FwElevation`). Orthogonal means every combination is expressible:
///    a small pill danger button must not be impossible because two knobs
///    were merged into one.
/// 3. **State** — caller-owned: `enabled`, `selected`, `loading`/`busy`,
///    `invalid`/`errorText`, `value`/`onChanged`.
/// 4. **Behavior & interaction** — `autofocus`, `focusNode`,
///    `onFocusChange`/`onHoverChange`, `mouseCursor`, `enableFeedback`,
///    `tooltip`, `shortcuts`/`actions`, `fullWidth`.
/// 5. **Field/form integration** — `controller`, `validator`,
///    `autovalidateMode`, `onSaved`, `textInputAction`, `keyboardType`,
///    `inputFormatters`. Mirror Flutter's names so muscle memory transfers.
/// 6. **Layout overrides** — sparing: `padding`, `constraints`, `alignment`.
///    If more than two are needed, the caller should wrap the component.
/// 7. **`*Style` theme classes** — one `FwXxxStyle extends
///    ThemeExtension<FwXxxStyle>` per component (e.g. `FwButtonStyle`),
///    resolving `variant × intent × size × WidgetState` to concrete visuals.
///    Registered per [FwTheme] preset so brand presets restyle every
///    component coherently.
/// 8. **`*StyleDelta` escape hatch** — a `style` constructor parameter taking
///    a *delta* applied over the resolved theme style. Unlimited restyling
///    without forking the widget and without 40 constructor params. Deltas
///    compose (theme → variant/size resolution → delta), never replace.
/// 9. **Headless/builder escape hatch** — behavior-only widgets with a
///    `builder(context, states)` slot, for bespoke visuals. Built on demand,
///    not upfront.
/// 10. **(Reserved)** — future cross-cutting concerns.
///
/// ## Constructor vs theme: the litmus test
///
/// - **Constructor**: identity/content, callbacks, per-instance state
///   (`value`, `selected`, `loading`), and variant/intent/size/shape when
///   they vary per instance.
/// - **Theme (`*Style`)**: everything that should be consistent app-wide
///   and change with a brand preset — colors per state, paddings, text
///   roles, radii, elevations, durations, focus-ring appearance.
///
/// Ask: *"would a brand preset want to change this globally?"* → theme.
/// *"Does this instance differ from its siblings?"* → constructor.
///
/// ## Color rule
///
/// Components never expose raw [Color] constructor parameters. Color is
/// always expressed as [FwIntent] or a [FwColorRole] resolved through the
/// theme's semantic layer; seeds are the only raw-color inputs and they
/// live on the theme axis (`FwTheme.fromSeed`), never inside token keys.
/// A repository test enforces this.

/// Standard component size. Metrics only: padding, minimum height, text
/// role, and icon size derive from the size. Size never changes the hit
/// area — every size keeps the theme's minimum touch target.
///
/// [scaleFactor] is the *default* proportional factor relative to [md];
/// components with exact metric tables take precedence over it.
enum FwSize {
  /// Dense toolbars, compact chips, table cells.
  xs,

  /// Small actions, dialog buttons.
  sm,

  /// The reference size. [scaleFactor] is 1.0.
  md,

  /// Prominent actions, form submits.
  lg,

  /// Hero CTAs, onboarding actions.
  xl,
}

/// Default proportional factor relative to [FwSize.md].
extension FwSizeScale on FwSize {
  double get scaleFactor => switch (this) {
    FwSize.xs => 0.625,
    FwSize.sm => 0.8,
    FwSize.md => 1.0,
    FwSize.lg => 1.25,
    FwSize.xl => 1.5,
  };
}

/// Shape family of a component, independent of [FwSize].
///
/// Shape is separate from size so "small pill danger button" stays
/// expressible. A component may additionally accept an explicit
/// `borderRadius` override, which wins over the shape.
enum FwShape {
  /// Fully rounded ends (maps to the `pill` radius token).
  stadium,

  /// Standard rounded corners (maps to the `md` radius token).
  rounded,

  /// Sharp corners (maps to the `none` radius token).
  sharp,
}

/// Icon placement relative to a label, using logical (not physical)
/// directions.
///
/// `start`/`end` are inline placements that flip automatically in RTL
/// locales; `top`/`bottom` stack the icon above/below the label and never
/// mirror. Physical `left`/`right` names are banned from new APIs — the
/// industry (MUI `startIcon`/`endIcon`, Ant Design `iconPlacement`,
/// Flutter's own `IconAlignment`) has converged on logical directions.
///
/// The icon–label gap defaults to the 8px consensus token (`FwSpace.s2`
/// at the default unit).
enum FwIconPosition {
  /// Icon before the label in the inline axis; flips in RTL.
  start,

  /// Icon after the label in the inline axis; flips in RTL.
  end,

  /// Icon stacked above the label.
  top,

  /// Icon stacked below the label.
  bottom,

  /// Icon only: the component adopts square icon metrics and drops the
  /// label slot. Requires a `semanticLabel` (enforced by lint/tests) and
  /// keeps the theme's minimum touch target even when the glyph is small.
  only,
}

/// Convenience predicates for [FwIconPosition].
extension FwIconPositionX on FwIconPosition {
  /// Inline (row-axis) placements: [FwIconPosition.start]/[end].
  bool get isInline =>
      this == FwIconPosition.start || this == FwIconPosition.end;

  /// Stacked (column-axis) placements: [FwIconPosition.top]/[bottom].
  bool get isStacked =>
      this == FwIconPosition.top || this == FwIconPosition.bottom;
}

/// Where a loading indicator appears relative to the content it replaces.
///
/// The default across the framework is [start]: the spinner replaces the
/// leading icon in place while the component holds its width, so layout
/// does not jump when busy state toggles.
enum FwLoadingPosition {
  /// Replaces the leading icon (or leading edge) in place.
  start,

  /// Sits at the trailing edge.
  end,

  /// Centers over the content.
  center,
}
