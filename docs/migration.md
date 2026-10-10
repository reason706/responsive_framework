# Migration guide

## 0.1 → 0.2 (enhancement merge)

The enhancement waves land in 0.2. Breaking changes with codemods:

| Before (0.1) | After (0.2) | Notes |
|---|---|---|
| `FwButtonSize.md` | `FwSize.md` | Shared enum across components |
| `FwButton(leading: icon)` | `FwButton(icon: icon, iconPosition: FwIconPosition.start)` | Logical start/end; RTL-flips |
| `FwButton(trailing: icon)` | `FwButton(icon: icon, iconPosition: FwIconPosition.end)` | — |

Non-breaking additions: `FwButtonVariant.tonal`, `FwAsyncButton`,
`FwFab`/`FwSpeedDial`, slider `leading`/`trailing`/`thumbIcon`/`marks`,
`FwDataTable`, `FwCalendar`, `FwGauge`, `FwTimeline`, `FwTour`,
`FwReorderableList`, utilities (`FwDebouncer`, `FwDottedBorder`, …).

## General policy

- Deprecations carry `@Deprecated` with a migration note and survive two
  minor versions.
- Token key renames are listed in
  [reference/component-matrix](reference/component-matrix.md#upgrade-guides).
- The W3C token JSON is versioned alongside the Dart API; consumers
  should pin both.
