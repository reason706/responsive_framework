# ADR-001: Typed length system, root metrics, and resolution order

Date: 2026-10-09. Implements delivery task **DS-01** (public sizing API).

## Decision

Introduce a sealed `FwLength` hierarchy with validated factories instead of
`Object`, strings, or dynamic numeric arguments:

- `FwPx(double)` — fixed logical pixels. Unchanged by root metrics, density,
  breakpoints, or the system text scaler.
- `FwRem(double)` — multiples of the resolved root size `R` (default 16).
- `FwEm(double)` — multiples of the *declared* (unscaled) size of the nearest
  `FwEmScope`; throws an actionable error when no scope exists.
- `FwSpaceRef(FwSpace)` — reference to a named spacing token; ratios are
  root-relative (see `FwSpaceScale`).
- `FwFluid({min, max, fromWidth, toWidth})` — bounded interpolation between
  two lengths across a logical-pixel width interval.
- `FwResponsiveLength(Responsive<FwLength>)` — discrete breakpoint overrides
  wrapping the existing `Responsive<T>` contract.

## Validation policy

Constructors are **validated factories** (not bare const constructors) so
invalid configurations fail identically in debug and release builds:

- All scalar values must be finite and `>= 0`.
- `FwFluid` requires `fromWidth < toWidth` (strictly), both finite, and
  `FwPx` bounds; nested `FwFluid` endpoints are rejected (a fluid of fluids
  is not supported).
- `FwSpaceRef` tokens are fixed enum values, so no cycle checking is needed;
  token *ratios* are compile-time constants and cannot recurse.
- Negative padding, gaps, and gutters are invalid everywhere. Negative outer
  spacing remains deferred per the plan.

The factories are deliberately non-const. Framework-internal const instances
use private constructors. Component APIs that need const defaults keep using
`FwSpace`/`FwRadius` enums and resolve to typed lengths at build time.

## Root ownership

`FwMetrics` (root size, optional responsive root, density) is owned by the
application root:

- `FwRootScope(metrics: ...)` is the explicit, inherited root-metrics scope.
- `FwTheme` carries a convenience `metrics` default so `FwTheme.light()` still
  yields root 16 with no extra widget. Nested `FwThemeScope`/color overrides
  never change the root; only a nested `FwRootScope` (explicit) can.
- `FwMetrics.of(context)` resolves nearest `FwRootScope`, else the active
  `FwTheme`'s configured metrics. The root size itself is always a plain
  positive `double` — never a `FwRem` referring to itself.
- Breakpoint thresholds stay in logical pixels and are never expressed in a
  root whose size changes at those thresholds (avoids the unit cycle noted
  in the design-system spec).

An optional `responsiveRoot` (`Responsive<double>`) lets apps choose e.g. 16
below `lg` and 18 at `lg`. It resolves against the **explicitly selected**
responsive width (`FwContainerQuery`/`FwViewportQuery` via `FwResponsiveScope`),
never against an implicit screen size. The framework default keeps a fixed
root of 16.

## Resolution order

`FwLength.resolve(context)` follows the plan:

1. Validate metrics (root > 0, finite; responsive root values > 0).
2. Read the explicit responsive width from `FwResponsiveScope`
   (`FwContainerQuery` preferred; `FwViewportQuery` is opt-in).
3. Determine effective root and typography (`FwEm`) scope.
4. Resolve responsive overrides, then length values, then fluid endpoints.
5. Component code applies layout constraints and minimums afterwards.
6. Text rendering receives **declared, unscaled** font sizes; Flutter's
   `TextScaler` applies exactly once (see ADR follow-up for DS-05).

Root-relative sizing, responsive layout, and accessibility text scaling are
independent inputs: spacing never multiplies by the OS text scaler. A local
decoration that must follow rendered text uses an explicit text-relative
resolver (`TextScaler.scale(declaredSize)`), not an implicit global change.

`FwFluid` interpolation is computed against the same explicit width source as
step 2, outside the measured child, so resolution cannot create a layout
feedback loop. Widths are clamped: below `fromWidth` the value is `min`,
above `toWidth` it is `max`, never growing on ultrawide screens.

Refinement: the explicit width is read lazily — only when the length tree
(`FwFluid`, `FwResponsiveLength`) or a responsive root actually needs it. Plain
`FwPx`/`FwRem`/token resolution requires no query scope. The "never silently
substitute the screen" rule is preserved: when a width *is* needed and no
`FwResponsiveScope` exists, resolution throws an actionable error.

## Separation from the foundation API

- `paddingAll(double)` keeps meaning **logical pixels**; it is never
  reinterpreted as rem.
- `FwSpacing(unit:)` / `FwSpacing.of(token)` remain as the legacy
  context-free pixel scale. New code uses `FwSpaceScale` (rem ratios) and
  `FwInsets`; legacy custom units get a documented adapter at migration
  time (DS-11) rather than silent reinterpretation.
- Numeric parity at root 16 against the old `FwSpacing(unit: 4)` scale is a
  required test: `s4` must still resolve to exactly 16 logical pixels.

## Alternatives considered

- **Const constructors with asserts only**: rejected — asserts vanish in
  release builds, and the plan requires consistent validation.
- **CSS-style string lengths** (`'1.5rem'`): rejected — no compile-time
  checking, no IDE completion, locale/format ambiguity.
- **Breakpoints expressed in rem**: rejected — creates the unit-resolution
  cycle the plan forbids.
- **Implicit `MediaQuery.size` fallback when no scope exists**: rejected —
  matches the foundation's explicit-query contract; silent substitution
  caused the bugs this system is designed to prevent.

## Consequences

- New public API surface in `fw_core`: `lengths/`, `metrics/`, `tokens/`,
  `typography/` modules (see delivery.md §1 suggested locations).
- Components must thread `BuildContext` into length resolution; lengths are
  not plain numbers anywhere in new APIs.
- Follow-ups: DS-02 (implementation + numeric proof), DS-03 (fluid +
  responsive proofs), DS-04 (typography roles), DS-05 (TextScaler once).
