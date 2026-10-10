# Enhancement Plan — Completed Work Retrospective

**Status:** retrospective (everything below is implemented and merged to `main`)
**Coverage:** initial commit → gallery catalog wiring (`4f91e9c`), 83 commits
**Author:** built by Muse (Meta) with the repo owner, October 2026

This document is the companion to the forward-looking plans
(`component-demand-plan.md`, `delivery.md`). Where those say *what to build*,
this one records *what was built*, phase by phase, with the commit receipts —
so a future enhancement plan can start from ground truth instead of memory.

---

## 1. Foundation — design system (Wave 0)

The framework was deliberately built tokens-first. No component exists that
bypasses the token layer: a repo-wide discipline (added in E1, enforced in
review) forbids raw `Color` literals in public APIs.

| Commit | What landed |
|---|---|
| `949f4b3` | DS-01..DS-05 design-system foundation (color, typography, spacing) |
| `04c2adc` | DS-08 theme scopes, DS-09 borders/shadows/motion tokens |
| `9e3b2d7` | DS-07 semantic colors, DS-10 presets, DS-11 migration, DS-12 docs |
| `45ffedc` | M0.1 — 3-layer color tokens + named brand presets (`FwTheme.ocean()/.forest()/.sunset()/.monochrome()`) |
| `59f8906` | M0.2 — motion / elevation / haptic / grid tokens |
| `cadedba` | M0.3 — W3C token export via `build_runner` codegen |
| `9f505ac` | M0.4 — component documentation contract + atomic tiers in the gallery |

Cross-cutting rules established here and kept ever since: root-relative sizing,
responsive layout, and accessibility text scaling are three separate mechanisms;
Flutter `TextScaler` is applied exactly once (including nonlinear scaling).

## 2. Phase 2 — primitives (atoms)

| Commit | What landed |
|---|---|
| `73542a3` | 2a — action system (A01/A02/A07): buttons, async button states |
| `0615005` | 2b — text primitives (T01/T03–T06, A03) |
| `4999a77` | 2c — layout primitives (L03–L07) |
| `136e7b5` | 2d — media primitives + tooltip (M01/M03/M05, O05) |
| `6e3221c` | 2e — display primitives (D01/D02) + Phase 2 exit gate |

## 3. Phase 3 — forms & feedback

| Commit | What landed |
|---|---|
| `8e4a76e` | P3.1 — F01 field shell + typed field state (`FwFieldState`: dirty/touched/async-in-flight) |
| `a6cad14` | P3.2 — F02/F03/F12 text inputs |
| `23f154b` | P3.3 — F04–F08 selection inputs |
| `e3600bb` | P3.4 — F09 slider + expansion |
| `9f32112` | P3.5 — F22/F21+/F23 new inputs: OTP, rating, phone |
| `fcd8ff8` | P3.6 — B01/B03–B07 feedback: alert, progress, skeleton, state panel |
| `397d9b6` | P3.7 — form recipes + Phase 3 exit gate |

## 4. Phase 4 — overlays, pickers, toasts, notifications

| Commit | What landed |
|---|---|
| `d4400e9` | P4.1 — O01/O02/O03 dialog, confirmation, bottom sheet |
| `b394a0a` | P4.2 — O03/O04/O06/O07 drawer, popover, menu, context menu |
| `013c1f5` | P4.3 — F10/F11/F13/F14/F15/F16 pickers and advanced inputs |
| `3b0c278` | P4.4 — B02 toast service + B08 task progress list |
| `9494754` | P4.5 — B11 notification center (with in-app notification header; overflow fixed with a `Wrap`) |
| `ede202f` | P4.6 — Phase 4 exit gate: event-scheduling recipe |

## 5. Enhancement waves E1–E6 (interleaved with Phases 4–5)

The waves cut across phases to raise quality rather than add breadth:

| Wave | Commit(s) | What landed |
|---|---|---|
| E1 | `85ae12e` | Shared parameter vocabulary + prop taxonomy + Color API discipline |
| E2 | `39f66af`, `6122a54`, `0301057` | Button icon placement (Preline research), async states, FAB/speed dial, `FwFocusRing`; loading spinner honors reduced motion |
| E3 | `694445f`, `90e4603` | Slider icon slots + thumb glyph + fill control + marks + error state |
| E4 | `4cb7704` | S-tier components: data table, inline calendar + range, gauge, QR display |
| E5 | `29bd5df` | A-tier components: timeline, tour, reorderable list, sticky headers, resizable panels, chat bubble, signature pad, color picker |
| E6 | `780a7cf` | Utilities + E5 verification fixes |

## 6. Phase 5 — navigation & adaptive structure

| Commit | What landed |
|---|---|
| `addd2cd` | P5.1 — A04/A05/A06 action buttons (button group, segmented, split button) |
| `62396cb` | P5.2 — A09 copy action, A10 slide-to-confirm, A11 hold-to-confirm (gesture confirmations from the demand plan) |
| `47f1735` | P5.3 — N01–N04 navigation core (tabs, navbar, sidebar, breadcrumb) |
| `985b341` | P5.4 — N05–N08 navigation completion (pagination, stepper, bottom nav, rail) |
| `97663e7` | P5.5 — L08–L10/L12 adaptive layout + R01 onboarding flow |
| `0b436ad` | P5.6 — Phase 5 exit gate: dashboard + master-detail recipes |

## 7. Phase 6 — data display + media

| Commit | What landed |
|---|---|
| `fe8936a` | P6.1 — T02/T07/T08 text display: rich text, quote/lists, code/kbd |
| `7ef1aa0` | P6.2 — M02 `FwFigure` + M04 `FwAvatarGroup` |
| `8475793` | P6.3 — B09 `FwStatusDot` + D03 `FwAccordion` |
| `2b0115c` | P6.4 — D04 data table + D05 responsive cards + D07 timeline |
| `a70c649` | P6.5 — researched additions: carousel, photo viewer, swipeable actions, pull-to-refresh/infinite loading, stat cards |
| `c296820` | P6.6 — exit gate: searchable/paginated data-page recipe |

## 8. Phase 7 — docs, pilots, release

| Commit | What landed |
|---|---|
| `db2cf94` | P7.1 — final documentation structure + docs API link test |
| `b0dc010` | P7.2 — pilot apps (settings, dashboard, marketing) built on **public exports only** + friction log. The pilots caught a real bug: `FwToastHost` crashed inside `MaterialApp.builder` — fixed. |
| `648c425` | P7.3 — integration findings: platform feasibility (validation on web), dependency graph, layering note |
| `01a2f9f` | P7.4 — release readiness: changelog, package version bumps to 0.2.0, deprecation policy |

## 9. Integration, audit & the F11 fix

| Commit | What landed |
|---|---|
| `72911d4` | Merge: enhancement waves into the component catalog |
| `7c6d11f` | Removed duplicate `FwClipboard` from `fw_utilities` |
| `6b76ff6` | T09 `FwReadMore` + A08 FAB gallery board |
| `7c13403` | D11 `FwTreeView` |
| `5f354e8` | Token discipline + SpeedDial ticker lifecycle fix (merged audit) |
| `03e57b7` | **Audit-found gap:** F11 number-field long-press repeat. Holding the stepper buttons now repeats every 90ms until release or min/max; uses raw pointer `Listener` because `IconButton` tooltips own a competing long-press recognizer. |

Duplicate reconciliation during integration: kept the controlled `FwDataTable`
(ported filtering + pagination), kept the status-label/actions `FwTimeline`
(ported icon + dense spacing), unified the gallery boards.

## 10. Open-tasks completion (final build session)

The last items the demand plan called out were built in one session on three
feature branches, then merged:

| Commit(s) | What landed |
|---|---|
| `d2ac0e7` | `FwTagInput` (+F25): chips-inside-the-field editor — Enter/separator commit, chip delete + Backspace removal, `maxTags`, per-tag validator, duplicate policy, `FormField<List<String>>` |
| `6636f15`, `feb9690` | Utils backlog: `FwSemanticsDebugger` (dev overlay), `FwNumberFormat` / `FwCurrencyFormat` / `FwDateFormat` — pure-Dart, zero-dependency (`intl` deliberately not added; documented) |
| `932166a`, `0a7e375` | `FwAutoSkeleton`: skeletonizer-style auto bones — a `RenderProxyBox` lays out the real child and paints one rounded-rect bone per leaf `RenderBox` in the token skeleton color (static; shimmer is a follow-up) |
| `10b6fa0`, `1fa0056`, `db46e48` | `FwFormController`: `ChangeNotifier` with field registration via `FwForm` scope (+ `formName` on 6 fields), `validateAll()`/`validateFields()` (sync then async, `isValidating`), dirty/touched/valid aggregates, `setVisibleWhen` conditional visibility (hidden fields excluded from validation + `values`), `FwFormVisibility` section widget, wizard hook for `FwStepper.onStepContinue`. Also fixed two real bugs: setState-during-build in registration, and `FwTextField`/`FwTextArea` `initialValue` shadowing. |
| `609fcff`, `d17e198` | Adaptive (Cupertino) foundation: `FwPlatformOverride` (`.iOS`/`.android`/`.system`), `FwAdaptiveButton/Switch/Dialog/Indicator/Slider/DatePicker` — Cupertino widgets on iOS, framework components elsewhere. Full per-component iOS coverage is 2.x; the roadmap is in `docs/roadmap.md`. |
| `33c556f`, `4f91e9c` | Gallery doc boards for all six, wired into the catalog tier sections |
| `29e7c51`, `eadeb99`, `70dc6af` | Merges into `main` |

## 11. Verification record

- **`5f354e8` (pre-open-tasks):** full `dart run melos run check` green —
  605 tests (fw_components 401, fw_core 133, fw_layout 35, fw_gallery 23,
  fw_utilities 8, fw 2, pilots 3), analyzer clean, format clean, gallery web
  build successful, 320px / 2×-text / RTL stress passing.
- **Open-tasks branches:** each verified scoped-green before merge
  (fw_components 424/424 incl. 13 tag-input + 3 semantics-debugger + 4
  auto-skeleton + 12 form-controller + 13 adaptive tests; fw_utilities 26/26;
  analyzer `--fatal-infos` clean; format clean).
- **Post-merge full check:** re-run in progress at time of writing; results to
  be recorded here.

Known test-environment traps (for future contributors): default test surface
is 800px wide; the gallery has a narrow/2×-text/RTL stress test that catches
real overflows; Flutter 3.35 semantics flags use named getters; target
tooltips, not glyphs, in chip tests.

## 12. Deliberately deferred (2.x candidates)

Explicitly *not* in 1.0 — recorded so the next enhancement plan doesn't
re-litigate them:

- Full per-component iOS variants (foundation + 6 components shipped; roadmap in `docs/roadmap.md`)
- Cached-image disk-cache contract, Markdown rendering, hover card
- `*Style` / `*StyleDelta` theme system
- `FwAutoSkeleton` shimmer pass
- Form-controller wiring for wrapper fields (`FwNumberField`, `FwDateField`, `FwPhoneField`, `FwRatingInput`)
- Original 1.x items and optional adapters (excluded by scope decision)

## 13. By the numbers

- **83 commits**, 6 packages (`fw`, `fw_components`, `fw_core`, `fw_layout`, `fw_token_gen`, `fw_utilities`)
- **45 component source files**, 46 barrel exports in `fw_components`
- **64 test files** across packages + apps
- **605+ tests** green at last full check (count grew with the open-tasks work)
- Gallery: every component carries a doc board (anatomy / properties / layout / do–don't / a11y) with a live demo
