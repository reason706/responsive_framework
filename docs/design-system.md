# Design System

This document is the contract for the framework's design tokens: what they
mean, who owns them, and how components must use them. It accompanies
`docs/planning/design-system.md` (the build plan) with the as-built rules.

## Token scale

Sizes are **typed lengths** (`FwLength`), never bare doubles in component
code:

| Type | Meaning | Example |
| --- | --- | --- |
| `FwPx` | Logical pixels, root-independent | `FwPx(1)` hairline |
| `FwRem` | Root-relative | `FwRem(1)` = root size |
| `FwEm` | Relative to the ambient `FwEmScope` | `FwEm(1.5)` |
| `FwSpaceRef` | Named spacing token | resolves via `FwSpaceScale` |
| `FwFluid` | Interpolates between widths | headings |
| `FwResponsiveLength` | Breakpoint-keyed values | page insets |

`FwPx` vs `FwRem` is a deliberate role choice, not a unit preference:
a 1px divider stays 1px when the root grows (`FwBorders.hairline`);
structural padding scales with the root. If you are unsure which to use,
ask which behavior the user expects when they raise the root size.

## Root ownership

One rule governs everything: **the application root owns the root size.**

- The default root is 16. Change it with `FwRootScope` at the app root or
  `FwTheme(metrics: FwMetrics(rootSize: …))`.
- Nested color/theme scopes **inherit** the root; they never redefine it.
  A dark dialog must not accidentally resize the app.
- `FwRem` and `FwSpaceRef` resolve against the nearest `FwRootScope` or the
  theme's metrics. There is no implicit viewport fallback: a responsive or
  fluid value used outside a query scope throws in debug.
- Raw logical pixels are allowed only where the design is intentionally
  root-independent (hairlines, minimum touch targets).

## Theme anatomy

`FwTheme` is a `ThemeExtension`, so it rides along with `ThemeData` and
reaches native Material widgets through `toThemeData()`:

- **colors** — `FwColors`: a `ColorScheme` base plus explicitly generated
  status pairs (success/warning/info), each contrast-validated (≥ 4.5:1).
  Components reference `FwColorRole`, never palette numbers.
- **typeScale** — `FwTypography`: named roles (`h1`…`h6`, `body`, `label`,
  …) with fixed or fluid sizes. Roles resolve with the ambient root; the
  `TextTheme` snapshot is rebuilt when the scale or metrics change.
- **spaceScale** — `FwSpaceScale`: root-relative named tokens plus semantic
  aliases (`controlInline`, `cardInset`, `pageInset`, …). Aliases apply the
  active density; raw tokens do not.
- **borders / shadows / motion** — typed widths, elevation levels with
  light/dark variants, durations with a reduced-motion policy.
- **breakpoints** — the responsive ladder (`xs`…`xxl`).
- **minTapTarget / focusWidth** — 48px minimum target (asserted), focus ring
  width.

### Override precedence

```
explicit widget property
→ widget partial style
→ nearest component-theme scope (FwThemeScope)
→ application component theme
→ global semantic tokens
→ documented built-in fallback
```

Build scoped overrides with `parent.copyWith(…)` inside `FwThemeScope`;
unspecified properties inherit. Use `FwOverride` to distinguish "absent"
from "explicitly cleared" for nullable component fields.

### Component states

`FwStateRoles` maps `WidgetState` sets to color roles with fixed
precedence: **disabled > pressed > hovered > selected > invalid > focused
> base**. Disabled always wins. Invalid and focused coexist — invalid
selects the color while focus keeps its separately drawn ring, never
color alone. Busy disables activation; it is not a widget state.

## Text scaling

The contract from the plan, enforced by tests:

- The user's text-size preference is applied **exactly once**, at the
  outermost framework-owned text root (see `FwRootScope`/theme wiring).
- Components and nested scopes must not re-apply it.
- Non-linear scalers are supported; tests cover a 2× non-linear scaler.
- Layouts must **adapt or scroll** at large text: no fixed label heights,
  no truncation of essential text. `textSubtle`/`caption` roles are for
  secondary annotations only.

## Spacing

- Use `theme.spaceScale.of(FwSpace.s4, context)` for raw tokens and
  `theme.spaceScale.resolveAlias(FwSpaceAlias.cardInset, context)` for
  semantic intent.
- Density (`FwDensity.compact`) tightens control padding and gaps; it
  never shrinks the 48px touch target or body text size.
- Directional insets (`FwInsets`) resolve start/end through
  `Directionality` — test layouts in RTL.

## Migration notes

Components migrated from the legacy pixel scale (`FwSpacing.of`) keep
**numeric parity at root 16**: `s4` still resolves to 16px. Behavior
changes only when the root or density changes, which is the point. The
legacy `FwSpacing` remains for non-component code during the transition.

## Playground

The gallery app (`apps/gallery`) is the living playground:

- Root-size switcher (16/18/20) proving rem-based sizing.
- Design-system specimens: lengths, spacing, typography, scope demo.
- Theme presets strip: light, dark, high-contrast ×2, compact,
  comfortable — all rendered live.
- Width slider driving real container queries; RTL + 2× text stress test.

## Theme contract checklist

Before shipping a custom theme, verify:

1. All semantic roles resolve (no throw) in light and dark.
2. Text pairs ≥ 4.5:1; focus ring ≥ 3:1 against surfaces.
3. Touch targets ≥ 48px in every density.
4. Layouts scroll or adapt at 2× text with no overflow exceptions.
5. Scoped overrides change only what they pass to `copyWith`.
