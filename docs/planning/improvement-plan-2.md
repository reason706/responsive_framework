# Improvement Plan 2 — Tokenization, Spacing Discipline & UI/UX Hierarchy

**Status:** proposed — plan only, nothing here is implemented
**Date:** 2026-10-10
**Follows:** `completed-work-retrospective.md` (what was built), `component-demand-plan.md` (component demand)

## 1. Goals

1. **Zero hardcoded spacing in `src/`** — every `EdgeInsets`, `SizedBox`, `BorderRadius`,
   and wrap-spacing literal migrates to a token; a lint rule keeps it that way.
2. **Deeper tokenization** where the research shows gaps: micro spacing steps, hero-scale
   steps, icon sizes, z-index, opacity, and per-component-class radius.
3. **Standardized gap / padding / margin APIs** — token-gated layout primitives
   (`FwGap`, `FwBox`, `FwWrap`, `FwInline`) and a documented "spacing lives on the
   container" convention.
4. **Stronger visual hierarchy** — elevation applied consistently with M3-correct
   defaults, density honored by every component, completed type roles.
5. **More components only with evidenced demand** — each P4 candidate needs a demand
   note; no speculative widgets.

Non-goal: changing the 4px root-relative rhythm or the t-shirt token naming
(deliberate decisions, documented in `spacing.dart`).

## 2. Research summary

### 2.1 Spacing systems

| System | Base unit | Steps | Naming convention |
|---|---|---|---|
| Material 3 | 4dp | 8–10 | Component-defined |
| Apple HIG | 8pt (4pt allowed for fine adjustment) | 8 | Semantic |
| IBM Carbon | 2px | 13 (`spacing-01`…`spacing-13`, 2px→160px) | Numeric + component aliases (`xxs`→`section`) |
| Atlassian | 8px | 14 (`space.025`…`space.1000`, 2px→80px) | Percentage of base; negative tokens exist |
| Shopify Polaris | 4px | 18 (`--p-space-100`…`--p-space-3200`, 4px→128px) | Hundreds = px |
| Tailwind | 0.25rem (4px) | 34 | Unit multiplier |
| GOV.UK | 5px | 10 | Idiosyncratic |

**Converged rule (Material 3, Apple HIG, Atlassian agree): two scales coexist.**
Component-internal padding and icon margins use a **4px unit** (`4 / 8 / 12 / 16`);
layout-level gaps and section padding use an **8px unit** (`8 / 16 / 24 / 32 / 48 / 64`).
The 8pt grid is a layout convention; inside inputs and buttons you need 4px
precision or controls look bloated.

Sources:
- https://github.com/zeptillionairplex/karpathy-claude-code-prompt-principle/blob/HEAD/.claude/skills/design-craft/docs/02-design-system-tokens.md
- https://github.com/tiantangcao1980-web/super-skill/blob/HEAD/skills/04-design-system/designdna/skills/apple-hig/SKILL.md
- https://github.com/ownware-ai/ownware/blob/HEAD/packages/cortex/profiles/ownware-design/skills/platform-rules/SKILL.md
- https://github.com/zeptillionairplex/karpathy-claude-code-prompt-principle/blob/HEAD/.claude/skills/design-craft/docs/03-layout-and-ia.md
- https://github.com/madebyaris/design-rules-ai/blob/HEAD/.mba-template/design-systems/ibm-carbon/spacing-scale.md
- https://github.com/yiurenma/workflow-claude-config/blob/HEAD/plugins/ibm-carbon-design/skills/ibm-carbon/SKILL.md
- https://github.com/bobbyaxerol/awesome-portal/blob/HEAD/Design/ibm_design.md
- https://superdesign.dev/blog/atlassian-design-system
- https://honcho.agency/design-systems/glossary/spacing-scale

### 2.2 Gap / padding / margin conventions

- **Atlassian primitives** (`@atlaskit/primitives`): `Box` (padding via logical
  props), `Stack` (vertical, `space` prop), `Inline` (horizontal wrap, `space` +
  `rowSpace`). Spacing props are **token-gated**: `space="space.200"` is valid,
  an off-scale value is a type error — so spacing decisions stay on the scale
  without anyone reading a lint message.
  - https://atlassian.design/components/primitives/inline
  - https://atlassian.design/components/primitives/stack
- **Logical properties for RTL**: `paddingInline` / `paddingBlock` /
  `paddingInlineStart` / `paddingBlockEnd` (Atlassian Box) — writing-mode safe,
  no physical left/right in APIs.
- **The container owns the gap.** Mature systems put spacing on the container's
  `gap`, never as margins on children — margins collapse unpredictably and break
  reordering (Atlassian/Polaris/Primer pattern).
  - https://github.com/staple-lab/design-system-skills/blob/HEAD/plugins/design-system/skills/design-system-architect/references/component-roadmap.md
  - https://github.com/yu-aimaker/awesomedesignsystem/blob/HEAD/design-system/foundations/spacing-layout.md
- **Layout primitives ship early** (wave 1) in new systems: they are what stops
  product teams hand-rolling flex divs with raw dimensions.

### 2.3 Visual hierarchy

- **Four hierarchy primitives: size, weight, color, spacing.** Change one at a
  time to express priority — three CTAs that are all bold + accent + large are
  flat. Group related items with shared spacing; separate sections with larger
  spacing (8pt rhythm).
- **Elevation:** Material 3 uses tonal elevation (surface tint via opacity) plus
  shadow elevation — cards at elevation-1, FAB at elevation-3; don't stack 8dp
  shadows. Carbon takes the opposite stance: no shadows at all, depth via
  surface-color layering and 1px hairlines. Either stance is valid; mixing them
  is not. (This framework already has elevation tokens; §3.1 picks the M3 stance
  explicitly.)
- **Density:** four zones — spacious (marketing), comfortable (default consumer),
  compact (power tools), dense (dashboards). Density scales spacing tokens and
  component padding; **touch targets never shrink** (44pt iOS / 48dp Android /
  WCAG 2.5.8). This framework's `FwDensity` (compact 0.875 / comfortable 1.0 /
  spacious 1.25) already encodes this and already protects the 48px target.
  - https://github.com/metedata/design-crit/blob/HEAD/skills/crit-density-spacing/SKILL.md
- **Radius per component class**, not a single `--radius`: buttons/inputs smaller,
  cards/modals larger, pills for badges/chips (research consensus).

### 2.4 Component-demand signals (for P4)

Prior demand notes already on file: `component-demand-plan.md`,
`docs/roadmap.md` (2.x iOS variants), and the deferred list in the retrospective
§12 (skeleton shimmer, hover card, command palette, description list, side sheet).
P4 candidates below are drawn only from those sources — nothing invented.

## 3. Repo audit (2026-10-10, `main` @ `ceed4e2`)

What is already good:

- `FwSpace`: 12 root-relative tokens (`s0`–`s24` = 0–96px at root 16), 4px rhythm.
- `FwSpaceAlias`: 8 semantic aliases (controlInline/Block, fieldGap, cardInset,
  pageInset, sectionGap, overlayInset) — density-scaled.
- `FwDensity`: compact/comfortable/spacious with `gapScale`; 48px touch-target floor.
- `FwHStack`/`FwVStack`: token-gated gap stacks (the Atlassian Stack pattern, already).
- `FwTextRole`: 14 roles (displayLg/Sm, h1–h6, lead, body, bodySm, caption, label, code).
- Elevation tokens exist; W3C token export via codegen.

Gaps found (counts from direct grep of `packages/fw_components/lib/src`):

| # | Finding | Count |
|---|---|---|
| 1 | Numeric `SizedBox(width:/height:)` literals | ~20 instances across 15 files |
| 2 | Raw `EdgeInsets` literals (`all(12)` ×2, `all(4)` ×1, `symmetric(6,2)` ×2, `symmetric(12,8)` ×1) | 6 |
| 3 | Raw `BorderRadius.circular(2)` | 1 |
| 4 | Raw `Wrap`/`Grid` spacings (`spacing: 6`, `runSpacing: 6`) | 2 |
| 5 | No single-spacer widget | `FwGap` does not exist |
| 6 | No padding primitive | `FwBox`/`FwPad` do not exist |
| 7 | No token-gated `Wrap` | does not exist |
| 8 | Density honored in 7 component files only; no per-subtree density override widget | — |
| 9 | Elevation tokens used in 7 component files; most overlays lack an `elevation` prop | — |
| 10 | No micro spacing steps (2px/6px — cf. Atlassian `space.025`/`space.075`) | — |
| 11 | Scale tops out at 96px (`s24`); no hero-scale step (cf. Polaris 128px, Carbon 160px) | — |
| 12 | No icon-size tokens, no z-index tokens, no opacity scale, single radius posture | — |
| 13 | `FwTextRole` lacks a micro-label/overline role (research: 11px, 600, uppercase, 0.06em) | — |

## 4. Phased work items

### P1 — Spacing-token expansion + lint rule

**1.1 Expand `FwSpace` at both ends.**
What/why: add `s32` (128px — Polaris max) and `s40` (160px — Carbon max) for
hero/section scale; add micro steps for the 2px/6px slots (Atlassian `space.025`/
`space.075` precedent) via new `FwSpaceAlias` entries (`iconGap`, `hairlineGap`)
rather than new t-shirt steps, keeping the t-shirt scale on the 4px rhythm.
Standard: §2.1. Acceptance: `tokens.yaml` + codegen + W3C export updated;
gallery scale board renders the new steps; numeric parity at root 16 preserved.
Packages: `fw_core`, `fw_token_gen`. Breaking: no (additive).

**1.2 New token families.**
What/why: `FwIconSize` (16/20/24/32), `FwZIndex` (overlay layer scale),
`FwOpacity` scale, and per-class radius tokens (`FwRadiusClass`:
button/input/card/modal/pill — §2.3). Standard: §2.1–2.3.
Acceptance: tokens resolve via theme, documented in gallery foundations board,
W3C export includes them. Packages: `fw_core`, `fw_token_gen`. Breaking: no.

**1.3 Lint rule `no_hardcoded_spacing`.**
What/why: a `custom_lint` rule flagging numeric `EdgeInsets`/`SizedBox`/
`BorderRadius`/`spacing:` literals in `lib/src` — the E1 color-lint pattern
applied to spacing. Standard: §2.2 (token-gated props). Acceptance: rule fires
on all §3 findings 1–4 and is clean after 1.4. Packages: tooling + CI.
Breaking: no (CI only).

**1.4 Migrate every leak.**
What/why: replace all §3 findings 1–4 with token equivalents.
Acceptance: lint clean; pixel-identical output at root 16 (gallery screenshot
diff or widget-test dimension assertions). Packages: `fw_components`.
Breaking: no.

### P2 — Gap / padding / margin component APIs

**2.1 `FwGap` — the single spacer.**
What/why: token-gated, axis-aware spacer replacing `SizedBox(width: 4)` etc.
Standard: §2.2 (Atlassian gap ownership). Acceptance: widget + 8+ tests
(token resolution, density scaling, RTL neutrality) + gallery board.
Packages: `fw_layout`. Breaking: no.

**2.2 `FwBox` — the padding primitive.**
What/why: `Box` with logical props (`padding`, `paddingInline`, `paddingBlock`,
`…Start/End`) typed to `FwSpace` — the Atlassian Box pattern, RTL-safe by
construction. Standard: §2.2. Acceptance: widget + tests incl. RTL logical
mapping + gallery board. Packages: `fw_layout`. Breaking: no.

**2.3 `FwWrap` — token-gated wrap.**
What/why: `Wrap` with `gap`/`runGap` typed to `FwSpace` (replaces the two raw
`spacing: 6` sites and all future ones). Standard: §2.2.
Acceptance: widget + tests + internal migration. Packages: `fw_layout`. Breaking: no.

**2.4 `FwInline` — wrapping horizontal flow.**
What/why: Atlassian Inline parity — horizontal flow that wraps, with token
`gap` + `rowGap` + alignment; `FwHStack` stays the non-wrapping variant.
Standard: §2.2. Acceptance: widget + tests + gallery board.
Packages: `fw_layout`. Breaking: no.

**2.5 Margin convention (docs + lint).**
What/why: codify "spacing lives on the container's gap, never as margins on
children" in the component contract; extend the P1.3 lint to flag `margin:`
with raw values on framework components. Standard: §2.2.
Acceptance: contract doc updated; lint flags new violations. Breaking: no.

### P3 — Hierarchy

**3.1 Elevation, applied consistently.**
What/why: audit every surface (dialog, bottom sheet, popover, menu, toast,
card, banner, drawer); add an `elevation` prop with M3-correct defaults
(card = 1, FAB = 3, dialog = 3); add a tonal-elevation (surface-tint) option
per M3. Explicitly adopt the M3 stance over Carbon's no-shadow stance and
document the choice. Standard: §2.3. Acceptance: props + tests + gallery
elevation board showing all levels. Packages: `fw_core`, `fw_components`.
Breaking: **visual** — minor version bump + migration note.

**3.2 Density everywhere.**
What/why: route all remaining control padding / row gaps through
`FwSpaceAlias` (density-scaled); add `FwDensityScope` for per-subtree density
override (e.g. a dense data table inside a comfortable page). The 48px
touch-target floor and no-body-text-shrink rules stay. Standard: §2.3.
Acceptance: gallery density switch visibly compacts every form/selection/
navigation component; test asserts touch targets ≥ 48px in compact mode.
Packages: `fw_core`, `fw_components`. Breaking: no.

**3.3 Complete the type roles.**
What/why: add `FwTextRole.overline` (11px, w600, uppercase, 0.06em
letter-spacing — the research micro-label) and `FwTextRole.numeric`
(tabular figures for data/dates). Standard: §2.3.
Acceptance: roles render per spec; gallery type board updated.
Packages: `fw_core`. Breaking: no.

**3.4 Hierarchy playground (gallery).**
What/why: an interactive board demonstrating the one-change-at-a-time rule
(size / weight / color / spacing) so consumers learn the system, not just the
widgets. Standard: §2.3. Acceptance: gallery board merged. Packages: gallery.
Breaking: no.

### P4 — New components (demand-gated)

Each candidate ships only with a demand note citing one of: `component-demand-plan.md`,
the retrospective §12 deferrals, or the hosted-plan items. Proposed slate:

| Candidate | Demand signal | Notes |
|---|---|---|
| `FwBanner` | Carbon/Atlassian pattern; persistent page-level messaging distinct from toast/alert | New API |
| `FwShimmer` | Retrospective §12 deferral (skeleton shimmer pass) | Extends `FwAutoSkeleton` |
| `FwHoverCard` | Retrospective §12 deferral | — |
| `FwCommandPalette` | Enhancement-plan item | — |
| `FwDescriptionList` | Hosted-plan item | Key-value dense list; pairs with P3.2 density |
| `FwSideSheet` | Hosted-plan item | — |

Acceptance per component: research note, implementation, 8+ tests, gallery
board (five-board contract), `melos run check` green. Packages: `fw_components`.
Breaking: no (all new APIs).

### P5 — Gallery & docs

- **5.1** Spacing scale board: every token rendered, both scales (4px component /
  8px layout), density preview toggle.
- **5.2** Layout primitives board: `FwGap` / `FwBox` / `FwWrap` / `FwInline` with
  live gap controls.
- **5.3** Elevation + density boards (supports P3.1/P3.2 acceptance).
- **5.4** Update `component-demand-plan.md` statuses for everything P4 ships.

## 5. Explicitly out of scope

- Full per-component iOS variants (separate 2.x track — `docs/roadmap.md`).
- `*Style` / `*StyleDelta` theme system.
- Changing the 4px root-relative rhythm or t-shirt naming (settled decisions).
- New components without a demand note (§4 P4 gate).

## 6. Breaking-change register

| Item | Kind | Handling |
|---|---|---|
| P3.1 elevation defaults | Visual | Minor version bump + migration note in changelog |
| All other items | None | Additive APIs, CI-only lint, or docs |
