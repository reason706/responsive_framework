# Color: 3-layer tokens

Color is layered so raw values never leak into components:

1. **Primitive** — `FwColorPrimitives`: brand seeds and hand-validated
   status pairs. The *only* place raw hex lives (enforced by test).
2. **Semantic** — `FwColors`: role-based tokens (`primary`, `onPrimary`,
   `surface`, `error`, …) including Material 3 roles. No brand names in
   keys; the brand lives on the theme axis.
3. **Component** — `ThemeExtension`s such as `FwButtonColors`: tokens that
   exist only where a component's mapping diverges.

```dart
// Layer 2 semantic roles resolve through the theme:
final colors = context.fwTheme.colors;
Container(color: colors.primaryContainer)
```

## Rules

- Components consume semantic roles or their own `ThemeExtension`; they
  never reference primitives.
- Every preset implements the **same keys** — light, dark, high-contrast,
  and brand presets are value-swaps on identical keys (key-parity is
  tested). Switching presets never changes layout.
- Text roles target ≥ 4.5:1 contrast; the high-contrast presets target 7:1
  (tested).
- Export the whole system as W3C Design Tokens JSON:
  `packages/fw_core/lib/src/tokens/tokens.json` (generated from
  `tokens.yaml` via `fw_token_gen`), so non-Flutter consumers read the
  same values.

See [brand presets](../theming/presets.md) · [token reference](../reference/tokens.md).
