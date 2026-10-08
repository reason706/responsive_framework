# Design system and responsive sizing specification

All type names and code examples in this document are **proposed APIs**. They
describe contracts to implement and test; they do not compile against the
current foundation unless explicitly identified as existing behavior.

## 1. Four independent inputs

The resolved interface combines four inputs with different responsibilities:

| Input | Controls | Does not automatically control |
| --- | --- | --- |
| Brand and color mode | Semantic colors, surfaces, component state palettes | Window geometry |
| Root design size | `rem` typography, spacing, relative component dimensions | Physical pixel density |
| Available width / height | Breakpoints, wrapping, adaptive layouts, fluid values | User accessibility preference |
| System `TextScaler` and accessibility settings | Text rendering, motion policy, high-contrast behavior | Blanket scaling of every gap/image/grid |

Density is another design preference affecting control padding, row gaps, and
visual minimums. Density must not shrink the supported touch target below 48
logical pixels or silently reduce body text. Device pixel ratio is used for
sharp rendering and image decoding, never as a multiplier on logical layout.

## 2. A Flutter equivalent of rem

CSS `rem` refers to the root computed font size. Flutter does not have CSS units
or a DOM root, so the framework must expose an explicit root design metric.

Let `R` be the resolved root size in Flutter logical pixels. The default is 16.

```text
FwRem(n) = n × R
FwPx(n)  = n logical pixels
FwEm(n)  = n × current declared unscaled typography size
```

Examples at the default root:

| Typed value | Root 16 | Root 18 | Intended use |
| --- | ---: | ---: | --- |
| `FwRem(0.25)` | 4 | 4.5 | Small gap |
| `FwRem(0.5)` | 8 | 9 | Control inset |
| `FwRem(1)` | 16 | 18 | Body size / common inset |
| `FwRem(1.5)` | 24 | 27 | Section spacing / heading |
| `FwRem(2)` | 32 | 36 | Large inset / heading |
| `FwPx(1)` | 1 | 1 | Hairline border |

This framework root is an application design preference, not a claim that
Flutter web reads the browser's CSS root font size. Browser zoom and operating
system text preferences have their own platform behavior; verify them in browser
and device tests. A later web-specific preference bridge would be an adapter.

### Proposed typed model

Use a sealed `FwLength` hierarchy instead of `Object`, strings, or dynamic
numeric arguments. Candidate types:

- `FwPx`: fixed logical pixels.
- `FwRem`: root-relative design length.
- `FwEm`: relative to an explicit typography scope; error if unavailable.
- `FwSpaceRef`: reference to a named spacing token.
- `FwFluid`: bounded interpolation between lengths across a width interval.
- `FwResponsiveLength`: wraps the existing `Responsive<FwLength>`.

Percentage/fraction dimensions belong in a separate constrained-layout API
(`FwFraction`, flex factors, or grid spans), not in the scalar length resolver.
`auto`, intrinsic sizing, and infinity are layout policies, not numbers to
resolve as rem. Initial lengths must be finite; negative padding/gaps are invalid.

Proposed examples:

```dart
const FwRem(1.25);                    // 20 at root 16
const FwPx(1);                       // remains one logical pixel
const FwSpaceRef(FwSpace.s4);         // named token, not numeric index 4
const FwResponsiveLength(
  Responsive<FwLength>(base: FwRem(1), lg: FwRem(1.5)),
);
```

Constructors should validate invalid configurations consistently in release
builds. Keep simple immutable values const-friendly where safe; use validated
factories when const restrictions would otherwise weaken essential validation.

### Root ownership and resolution order

The application root owns `FwMetrics`: root size, breakpoint specification,
density, and sizing policy. Normal nested theme scopes inherit that root;
changing a dialog's color mode must not accidentally redefine `rem`.

The root may be fixed or selected from a responsive configuration based on an
explicit root viewport measurement. A reusable component's fluid values normally
use its container scope. Local root overrides require an explicit root-metrics
scope rather than being a side effect of overriding colors.

Resolve in this order:

1. Validate logical-pixel breakpoints and root-size configuration.
2. Read the explicitly selected responsive width.
3. Determine root metrics and any typography scope.
4. Select responsive overrides, then resolve length values and fluid endpoints.
5. Apply layout constraints and component minimums.
6. Hand unscaled font sizes to Flutter's text rendering system.

The root must be a positive logical-pixel value, not a `FwRem` referring to
itself. Reject recursive token references. Do not define breakpoint widths in
terms of a root whose size changes at those same breakpoints.

## 3. Responsive and fluid behavior

Keep the existing six mobile-first breakpoint defaults (0, 576, 768, 992, 1200,
1400 logical pixels). A breakpoint activates at its exact minimum width. The
base value is always required and larger overrides inherit downward.

Root size should remain 16 by default. Applications may opt into a responsive
root such as 16 below `lg` and 18 at `lg`; this is a design choice, not a required
way to make everything responsive. The default framework should demonstrate
fluid headings while keeping normal body text at 1rem.

For a fluid length with widths `W0 < W1`, resolve endpoints `L0` and `L1` first:

```text
t = clamp((availableWidth - W0) / (W1 - W0), 0, 1)
resolvedLength = L0 + (L1 - L0) × t
```

Proposed example:

```dart
const FwFluid(
  min: FwRem(1.75),
  max: FwRem(2.5),
  fromWidth: FwPx(360),
  toWidth: FwPx(1200),
);
```

At root 16 this gives 28 at width 360, 34 at width 780, and 40 at width 1200.
At root 18 the same ratios produce 31.5, 38.25, and 45. Fluid interpolation is
bounded; it never reduces sizes below the documented minimum or keeps growing
on an ultrawide screen. Viewport-height scaling is not a default.

Reject equal/reversed width bounds, non-finite values, negative sizes where
unsupported, and unbounded measurement without an explicit policy. Resolve root
metrics outside the measured child to avoid layout feedback loops.

Use discrete overrides for structural changes (navigation, column count, layout
direction). Use fluid interpolation for suitable visual values (large headings,
hero padding). Do not interpolate enum states or fractional column counts.

## 4. System text scaling: apply once

Flutter supports `TextScaler`, including nonlinear scaling. Do not approximate
it by reading one global `textScaleFactor` and multiplying every token.

```text
declared font size = typography ratio × resolved root
rendered font size = systemTextScaler.scale(declared font size)
```

Pass the declared size to `TextStyle.fontSize` and let `Text` inherit the scaler.
If custom painting must measure text, pass the same scaler into `TextPainter`.
Do not pre-scale and then allow the widget to scale that number again.

Example: body text at root 18 has a declared size of 18. Under a linear 1.5 test
scaler the rendered size is 27, not 40.5. Actual device nonlinear behavior must
be tested separately; a 2× gallery slider is only a useful synthetic test.

Spacing uses the design root and density by default, not the OS text scaler.
Controls and text containers grow through content-driven height and wrapping.
If a local decoration truly needs to follow rendered text, use an explicit
text-relative resolver based on `TextScaler.scale(currentFontSize)`; document
that behavior rather than changing every `em` or `rem` implicitly.

Rules: no fixed label heights, no forced truncation for essential form labels,
no disabling text scaling globally, and no maximum scale cap by default. Use
scrolling and layout adaptation when enlarged content no longer fits.

## 5. Spacing system

Keep familiar named tokens while changing their future representation to root
ratios. This preserves a 4-logical-pixel rhythm at the default root.

| Token | rem ratio | Root 16 | Root 18 |
| --- | ---: | ---: | ---: |
| s0 | 0 | 0 | 0 |
| s1 | 0.25 | 4 | 4.5 |
| s2 | 0.5 | 8 | 9 |
| s3 | 0.75 | 12 | 13.5 |
| s4 | 1 | 16 | 18 |
| s5 | 1.25 | 20 | 22.5 |
| s6 | 1.5 | 24 | 27 |
| s8 | 2 | 32 | 36 |
| s10 | 2.5 | 40 | 45 |
| s12 | 3 | 48 | 54 |
| s16 | 4 | 64 | 72 |
| s24 | 6 | 96 | 108 |

Add semantic aliases: `controlInline`, `controlBlock`, `fieldGap`, `cardInset`,
`pageInset`, `sectionGap`, and `overlayInset`. Components should prefer these
aliases where the purpose matters. Themes can then compact forms without
changing every spacing token everywhere.

Create `FwInsets` with all, symmetric, and directional start/end factories.
Insets accept typed lengths/token references and resolve with metrics. Support
responsive insets and gaps without requiring five nested builders per widget.

Default semantic choices: page inset 1rem on narrow screens, 1.5rem on medium,
2rem on wide; card inset 1rem; field gap 0.75–1rem; section gap fluid 2–4rem.
These are design defaults, configurable through the theme.

Outer spacing is a wrapper/padding operation, not CSS margin collapse. Alignment
and flexible remaining space replace CSS `margin:auto`. Negative outer spacing
is deferred; negative padding and negative grid gutters are never supported.

## 6. Typography and fonts

Add `FwTypography`, `FwTextStyle`, and `FwTextRole` rather than relying entirely
on Material's default `TextTheme`. Continue mapping into Material where possible.
Text-role tokens include font family, weight, size expression, line-height
multiplier, tracking, decoration, and optional paragraph spacing.

Suggested default scale, before system text scaling:

| Role | Small → large rem | Root-16 size range | Line height | Weight |
| --- | --- | --- | ---: | ---: |
| displayLg | 2.5 → 4 | 40–64 | 1.1 | 700 |
| displaySm | 2 → 3 | 32–48 | 1.15 | 700 |
| h1 | 1.75 → 2.5 | 28–40 | 1.2 | 700 |
| h2 | 1.5 → 2 | 24–32 | 1.25 | 600 |
| h3 | 1.25 → 1.5 | 20–24 | 1.3 | 600 |
| h4 | 1.125 → 1.25 | 18–20 | 1.35 | 600 |
| h5 | 1.0625 | 17 | 1.4 | 600 |
| h6 | 1 | 16 | 1.4 | 600 |
| lead | 1.125 → 1.25 | 18–20 | 1.5 | 400 |
| body | 1 | 16 | 1.5 | 400 |
| bodySm | 0.875 | 14 | 1.5 | 400 |
| caption | 0.75 | 12 | 1.4 | 400 |
| label | 0.875–1, by control size | 14–16 | 1.4 | 500 |
| code | 0.875 | 14 | 1.5 | 400 |

Caption is for secondary annotations, not a default for critical instructions.
Font weights must match installed font faces; the current bundled Roboto example
does not contain every proposed weight. Add real font assets or choose supported
weights before presenting a preset as validated.

Fluid headings use container width by default, with an explicit viewport option
for hero sections. `TextStyle.height` is a multiplier, not an absolute rem height.
Tracking uses an explicitly resolved unit. Struts must not force clipping of
large text or scripts with different ascent/descent metrics.

### Font configuration

- Provide body, heading, and monospace families; default heading can inherit body.
- Support supplied `fontFamilyFallback`, package font references, and actual
  weights/styles; variable-font axes are an optional extension.
- Bundle example fonts with licenses. Do not require Google Fonts at runtime.
- Publish a guide for application-owned font assets, font loading, and fallback.
- Test Latin, Arabic/Hebrew, and at least one CJK example with licensed fonts.
- Do not treat RTL flipping as proof of script shaping or glyph coverage.
- Avoid changing root sizing while a font is loading; manage metrics consistently.

Text components include semantic headings, selectable body text, rich text,
links, inline code, quote/list helpers, and explicit truncation behavior. Rich
text recognizes typography inheritance and applies the inherited scaler once.
Links require link semantics and an application navigation callback/URI policy.

## 7. Theme architecture

Expand `FwTheme` into immutable groups rather than a flat list of properties:

| Group | Responsibilities |
| --- | --- |
| `FwColors` | Semantic roles and foreground/background pairs |
| `FwPalette` | Optional named tonal ramps, independent of semantic roles |
| `FwTypography` | Roles, font families, fluid sizes, tracking, line height |
| `FwSpaceScale` | Root-relative named tokens and semantic gaps/insets |
| `FwMetrics` | Root design size, density, physical sizing minimums |
| `FwRadii`, `FwBorders` | Shape scale and explicit pixel/rem border values |
| `FwShadows` | Elevation levels with color-mode-specific decoration |
| `FwMotion` | Durations, curves, reduced-motion policy |
| `FwLayoutTokens` | Breakpoints, container limits, navigation/dialog sizes |
| Component themes | Per-component defaults and partial overrides |

Root metrics remain separately owned even if stored inside the extension for
configuration convenience. Theme lookup and length resolution are distinct.

### Semantic colors

Define primary/secondary, success/warning/danger/info, background/surface/layer,
muted surface, normal/muted/subtle text, border, focus ring, selection, disabled,
scrim, and inverse pairs. Components reference semantic roles rather than
arbitrary palette numbers. Support hover, pressed, focused, selected, checked,
invalid, read-only, and disabled state colors where relevant.

Flutter `ColorScheme.fromSeed` supplies a useful Material base, not every custom
status color. Generate and validate additional semantic pairs explicitly.
Palette ramps (50–950 if useful) are a customization surface; publishing those
numbers does not establish that all combinations are readable.

Ship Default, Ocean, Forest, Sunset, and Monochrome only after testing them.
Each preset has light and dark, and a tested high-contrast mode/override policy.
Focus indication must remain visible against both its control and surroundings.
Use icons, labels, or patterns as well as color for status meaning.

### Override precedence

Resolve each property independently:

```text
explicit widget property
→ widget partial style
→ nearest component-theme scope
→ application component theme
→ global semantic tokens
→ documented built-in fallback
```

Unspecified values inherit. Distinguish absent override from explicit clearing
for nullable fields using an override wrapper/sentinel. Avoid replacing an
entire button style when the caller changes only its radius.

`FwThemeScope` must propagate its resolved Material adapter to descendants when
native primitives are used, or a locally dark card could contain light-theme
inputs. Provide scoped-theme examples for dialogs, sidebars, and inverse cards.

### States and interpolation

Use a shared typed component-state vocabulary; align with `WidgetState` where
possible. Disabled/busy must override activation; invalid/focused can coexist.
Document the precedence of combined states rather than testing states only alone.

Interpolate colors and suitable numeric tokens. Switch breakpoint sets, font
families, and structural layout choices discretely. Theme/motion transitions
must respect reduced-motion settings. Do not animate validation state in a way
that delays assistive-technology feedback.

Expose mode/preset selection without requiring Provider, Riverpod, or Bloc.
Preference persistence is an optional adapter; applications own storage and
decide whether user choice overrides the system theme.

## 8. Component sizing policy

Use xs/sm/md/lg/xl consistently, but define each component's actual metrics.
Visual controls may use a min-content height with rem-based padding; interactive
targets remain at least 48 logical pixels in the supported touch policy.

| Example | Proposed visual metric | Required layout behavior |
| --- | --- | --- |
| Small button | Label 0.875rem, block padding 0.5rem | Touch target >=48; label may wrap |
| Medium input | Body 1rem, block padding 0.75rem | Height grows with font/error/helper |
| Icon button | Icon 1.25rem, minimum target 48px | Accessible name; no label clipping |
| Avatar | Diameter 2.5rem by default | Bounded image; interactive wrapper owns target |
| Progress track | Thickness 0.25–0.5rem | Separate accessible percentage label |
| Divider | Border 1px | Does not become thick just because root grows |

Scale local text and spacing together through root metrics, not through global
screen-width ratios. Images adapt to aspect ratio and available space, not text
scale. Navigation adapts its structure; it does not merely shrink its labels.

## 9. Migration from the foundation

1. Add typed metrics/length resolution beside existing APIs; prove numeric parity
   at root 16 before migrating components.
2. Preserve `paddingAll(double)` as explicit logical pixels. Never reinterpret
   old `.paddingAll(16)` to mean sixteen rem.
3. Add context-aware spacing resolution. Current `FwSpacing.of(token)` has no
   context and cannot independently resolve container-responsive values.
4. Preserve custom `FwSpacing(unit: ...)` through an explicit legacy pixel-scale
   adapter or a documented 0.x migration; do not silently discard custom units.
5. Move buttons/cards/grid gaps to typed tokens; preserve default screenshots
   except for intentional documented typography changes.
6. Add typography roles and map them into the Material adapter; migrate gallery
   text from manually selected Material roles.
7. Add deprecations and upgrade examples before removing old methods. Freeze
   the consistent model before 1.0, with breaking changes confined to announced
   0.x releases.

## 10. Mandatory proof before adopting the model broadly

- Root 16/18/20 numeric resolution; fixed pixels remain unchanged.
- Every spacing token and fluid endpoint/midpoint/out-of-range case.
- Responsive-root and container-query interactions without circular resolution.
- System text scaling applied exactly once, including a nonlinear test scaler.
- Button/input/heading behavior with long text and enlarged text; no clipping.
- Nested color scopes do not accidentally redefine rem.
- Changing root/brand/mode invalidates only correct dependencies; no stale cache.
- Font fallback, actual weights, missing assets, and offline gallery rendering.
- Breakpoint boundary and unbounded-constraint errors remain deterministic.
- Existing root-16 layout behavior is preserved or explicitly documented.
