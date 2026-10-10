# Units: root, rem, em, pixels

The framework keeps three sizing concepts separate:

| Concept | What it is | Example |
|---|---|---|
| **Root-relative** | Lengths that scale with the configured root size | `FwSpace.s4`, `FwLength` |
| **Accessibility text scaling** | The OS text-size setting, applied exactly once | `MediaQuery.textScaler` |
| **Device pixels** | Physical rendering; never used directly in API | — |

## The root

`FwMetrics(rootSize: 16)` sets the root. At root 16, `FwSpace.s4` resolves
to 16 logical pixels — the same number as the legacy pixel scale, so
designs translate 1:1 by default. Change the root and every root-relative
length re-scales together; text set through `FwText` roles does **not**
double-scale because text sizing goes through the text scaler, not the root.

```dart
FwTheme.light(metrics: FwMetrics(rootSize: 18)).toThemeData()
```

## Typed lengths

- `FwSpace` — the spacing scale: `s0, s1, s2, s3, s4, s5, s6, s8, s10, s12, s16, s24`
  (named by px value at root 16; 8px base with a 4px exception for the
  smallest gaps). See [spacing](spacing.md).
- `FwSpaceAlias` — semantic aliases (`controlInline`, `fieldGap`,
  `cardInset`, ...) so a theme can compact forms without touching every token.
- `FwLength` / `FwInsets` — typed lengths and directional insets; negative
  padding is rejected at construction; resolve with `.resolve(context)` to
  logical pixels or `EdgeInsetsDirectional`.

## Rules

1. Components accept `FwSpace`/`FwLength`, never raw doubles for spacing.
2. Raw `Color(0x…)` literals live only in `FwColorPrimitives`; raw
   `BoxShadow` only in `FwShadows`. Repo tests enforce both.
3. Accessibility text scaling is applied exactly once, by Flutter's
   `TextScaler` — never multiply font sizes by the root.

See also: [fluid values](fluid.md) · [spacing](spacing.md).
