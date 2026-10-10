# Pilot friction log

Real apps built ONLY on public `package:fw/fw.dart` exports (no internal
imports). Each pilot compiles, runs widget tests, and is listed in
[recipes](../recipes.md).

| Pilot | Location | Exercises |
|---|---|---|
| Settings/forms | `apps/settings_app` | FwTextField validation, FwSwitch, FwSelect, FwSlider, FwButton loading, FwToast, theme preset switching |
| Dashboard/data | `apps/dashboard_app` | Adaptive nav (bottom/rail/sidebar), FwStat, FwDataTable sort/select, FwCard, FwAlert |
| Marketing/content | `apps/marketing_app` | FwText roles, FwCarousel, FwCard, FwAccordion, FwButton variants, FwAutoGrid, FwBadge |

## Defects found and fixed

### 1. FwToastHost in MaterialApp.builder was broken (FIXED)

**Severity: high** — the documented placement did not work.

`FwToast`'s doc comment recommends `MaterialApp(builder: (context, child) =>
FwToastHost(child: child!))`. Two failures in that placement:

1. **Missing Overlay.** The builder wraps the `Navigator`, which owns the
   `Overlay`. The toast's dismiss `IconButton` used Material's `tooltip:`,
   and `Tooltip` throws "No Overlay widget found" above the Navigator.
2. **100000px explosion.** Material's `Tooltip`-wrapped `IconButton`, given
   unbounded height (the toast positions with `bottom:` only), sizes itself
   to 100000×100000, overflowing the toast card. Reproduced with a bare
   Flutter `IconButton(tooltip:)` — no fw widgets involved.

**Fix** (`packages/fw_components/lib/src/toast.dart`): the dismiss button is
now a fixed `SizedBox.square(32)` wrapping `Semantics(label: 'Dismiss')` +
`IconButton` (no Material tooltip). Accessibility is preserved via the
semantic label; the hover tooltip is gone. Regression test:
"FwToast host in MaterialApp.builder (documented placement)" in
`packages/fw_components/test/feedback_test.dart`.

**Follow-up:** a future `FwTooltip` that doesn't need `Overlay`, or an
OverlayEntry-based toast, could restore the hover tooltip.

## API friction

### 2. FwText throws without FwResponsiveScope

`FwText` (and anything resolving responsive lengths) throws
"No FwResponsiveScope found" unless the app wraps its home in
`FwViewportQuery` (or a region in `FwContainerQuery`). Nothing in the setup
flow made this obvious; the pilot hit it immediately.

**Mitigation:** documented in [app setup](../start/app-setup.md) ("Responsive
scope" section). **Candidate improvement:** fall back to `MediaQuery` width
instead of throwing, reserving the error for genuinely ambiguous cases.

### 3. FwAccordion is controlled-only

No uncontrolled mode: a simple FAQ must be a `StatefulWidget` holding
`openIds` + `onOpenChanged`. **Candidate:** `initialOpenIds` for an
uncontrolled mode (still reporting via `onOpenChanged`).

### 4. Signature discoveries (docs/tests corrected)

- `FwAlert` takes `intent: FwAlertIntent` (`success/info/warning/danger`),
  not `FwIntent`.
- `FwStat` takes `trend: FwTrendDirection` (`up/down/flat`) plus
  `trendLabel: String` for the formatted text — not `trend: String`.
- `FwCard` takes `content:` (with `header`/`media`/`actions` slots), not
  `child:`.
- `FwAutoGrid` takes `minItemWidth:`, not `minCellWidth:`.
- Navigation widgets (`FwBottomNavigation`, `FwNavigationRail`, `FwSidebar`)
  report via `onDestinationSelected:`, not `onSelected:`.
- `FwToast.show` takes an `FwToast` object, not `(context, message)`.
- `FwTextField` uses `description:`, not `helperText:`.

## Accessibility findings

- Toast dismiss keeps its accessible name via `Semantics(label: 'Dismiss')`
  after the tooltip removal; verified by widget predicate in the regression
  test.
- `FwDataTable` selection is checkbox-only; row tap does not toggle
  selection. Fine for a11y (explicit control), but worth documenting.
- All pilots run inside `FwViewportQuery`; text scaling and density flow
  through the token system without pilot-side work.

## Dependency / size notes

- Each pilot depends ONLY on `flutter` SDK + `package:fw`. No third-party
  packages. `flutter pub get --offline` resolves from the workspace.
- No dependency impact: pilots add no new external dependencies to the
  framework packages.
- Size: not measured here (no native tooling in this environment — see
  P7.3). The pilots are thin; framework size is dominated by
  `package:fw_components`.

## P7.3 integration findings

### Platform feasibility (2026-10-10)

`flutter doctor`: Flutter 3.35.4 stable. **Only web is validatable here.**

| Target | Status |
|---|---|
| Web | ✅ Proven — gallery `flutter build web` passes in melos check |
| Android | ❌ No Android SDK installed; per task rules SDKs are not installed, so `flutter build apk` was not attempted |
| iOS | ❌ Linux host, no Xcode |
| Linux desktop | ❌ No clang++/GTK dev libraries |

Pilots are validated via `flutter test` (widget tests) + `dart analyze
--fatal-infos` (clean). They are not web-configured (no `web/` runner);
adding `flutter create . --platforms web` per pilot is a follow-up if
deployed web demos are wanted.

### Dependency graph (`flutter pub deps`)

- `fw_core` → flutter only. `fw_utilities` → flutter + fw_core.
  `fw_components` → flutter + fw_core (+ `characters` from the SDK).
- Pilots → flutter + `fw` only. Gallery → flutter + `fw` + `cupertino_icons`
  (third-party, gallery-only — not a framework dependency).
- **Layering inversion:** `fw_layout` → `fw_components`, because
  `FwAdaptiveScaffold` (in `fw_layout`) composes `FwBottomNavigation` /
  `FwNavigationRail`. This contradicts the documented "components → layout →
  core" direction. `docs/start/packages.md` now documents the exception.
  **Candidate:** move `FwAdaptiveScaffold` into `fw_components` to restore
  strict layering (breaking for direct `fw_layout` importers; safe under
  the `fw` umbrella).
