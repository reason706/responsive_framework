# Spacing

## The scale

`FwSpace`: `s0, s1, s2, s3, s4, s5, s6, s8, s10, s12, s16, s24` — named by
their pixel value at root 16, on an 8px base with a 4px exception for the
smallest gaps (`s1`–`s3`). This mirrors the px-value naming convention
(`$spacing-4` … `$spacing-160`) found in professional design-system case
studies, adapted to a t-shirt-friendly enum.

At root 16: `s4` == 16px, `s8` == 32px, `s1` == 4px.

## Semantic aliases

`FwSpaceAlias` names spacing by purpose so themes can re-target it:

| Alias | Purpose |
|---|---|
| `controlInline` / `controlBlock` | Padding inside controls |
| `fieldGap` | Gap between label/helper/error and between fields |
| `cardInset` | Padding inside cards and similar surfaces |
| `pageInset` | Page-level outer padding |
| `sectionGap` | Gap between page sections |
| `overlayInset` | Padding inside dialogs/sheets/menus |

Components prefer aliases where the purpose matters; raw `FwSpace` tokens
where the value is structural (grid gutters, icon gaps).

## Directional insets

`FwInsets` carries optional start/end/top/bottom `FwLength`s. Null edges
resolve to zero; negative padding is rejected at construction. Resolve with
`.resolve(context)` to `EdgeInsetsDirectional` — always directional, so RTL
layouts flip correctly.

Stacks, wrap, and grids take root-relative gaps (`FwHStack(gap: FwSpace.s3)`)
that resolve against the container width.
