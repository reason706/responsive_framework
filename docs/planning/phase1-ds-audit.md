# Phase 1 design-system audit — DS-06 / DS-10 / DS-12

Audited 2026-10-09 against `docs/planning/delivery.md` §3 acceptance criteria.
Working branch: `feature/component-catalog`.

## DS-06 — directional typed insets and semantic spacing ✅ COMPLETE

| Criterion | Evidence |
|---|---|
| Token map | `FwSpace` enum (s0…s24) in `packages/fw_core/lib/src/tokens/spacing.dart` |
| Semantic aliases | `FwSpaceAlias`: controlInline, controlBlock, fieldGap, cardInset, pageInset, sectionGap, overlayInset |
| Directional typed insets | `packages/fw_core/lib/src/lengths/insets.dart`; stacks/wrap/grid use root-relative gaps |
| Responsive gaps/insets | `FwHStack`/`FwVStack`/`FwWrap`/`FwAutoGrid` gaps resolve against container width |
| Root-16 parity | Documented in `FwSpaceScale` (s4 == 16px at root 16, matching legacy pixel scale); covered by `packages/fw_core/test/length_test.dart`, `metrics_test.dart` |
| RTL tests | Gallery narrow/2x-text/RTL stress test + length/metrics tests |

## DS-10 — tested theme presets ⚠️ PARTIAL — one gap

| Criterion | Evidence |
|---|---|
| Light/dark | `FwTheme.light()` / `FwTheme.dark()` ✅ |
| High-contrast policy | `highContrastLight()`/`highContrastDark()`, text pairs target 7:1 — tested in `packages/fw_core/test/presets_test.dart` ✅ |
| No unchecked raw color combinations | `FwColors` wraps `ColorScheme`; seed-generated schemes ✅ |
| **Named brand presets (Default/Ocean/Forest/Sunset/Monochrome)** | ❌ **MISSING** — `FwTheme.presets` ships Light, Dark, Light·High contrast, Dark·High contrast, Light·Compact, Light·Comfortable. "Ocean brand" exists only as a gallery seed-color toggle (`apps/gallery/lib/main.dart`), not as a tested preset |

**To close Phase 1:** add `FwTheme.ocean()`, `.forest()`, `.sunset()`, `.monochrome()` (light+dark each, or seed-parameterized with pinned seeds) to `FwTheme.presets`, extend `presets_test.dart` (Material mapping, contrast floors, no raw-color combos), and show them in the gallery preset picker.

## DS-12 — design-system documentation and playground ✅ COMPLETE

| Criterion | Evidence |
|---|---|
| Root control | Gallery root-size slider (`apps/gallery/lib/main.dart`) |
| Font control | Text-scale slider (1×–2×), typography roles card |
| Mode control | Light/dark toggle |
| Brand control | "Ocean brand" seed toggle |
| Density control | Compact/Comfortable presets |
| Local scopes | `_ScopeDemoCard` — locally scoped inverse theme with inherited root metrics |
| Rendered vs declared text explanation | Gallery: "Font sizes above are declared values. The text-scale slider …"; `FwTypography` docs state roles resolve to unscaled sizes applied once by `TextScaler` |
| Offline fonts | Roboto Regular/Medium/Bold bundled in `apps/gallery/assets/fonts/` with `LICENSE.txt`, registered in `pubspec.yaml` |

## Verdict

Phase 1 is complete **except** the DS-10 named brand presets. Suggested close-out
milestone: "DS-10b — tested brand presets" on this branch, then Phase 1 exit gate
(a branded page changing root size, heading font, spacing, theme) can be
re-verified and Phase 1 formally frozen before Phase 3 (forms) begins.
