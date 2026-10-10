# Changelog

All notable changes to the `responsive_framework` packages
(`fw`, `fw_core`, `fw_layout`, `fw_utilities`, `fw_components`).

## 0.2.0 — Component catalog + Phase 7 (unreleased)

New features across the framework. All packages bumped together; see
"Versioning" below.

### Design system (Wave 0)

- 3-layer color tokens (primitive → semantic → component) with key parity
  across themes (`M0.1`).
- Named brand presets: Ocean, Forest, Sunset, Monochrome (`DS-10`, `M0.1`).
- Motion, elevation, haptic, and grid tokens (`M0.2`).
- W3C Design Token JSON export via `build_runner` codegen (`M0.3`).
- Component documentation contract + atomic tiers in the gallery (`M0.4`).

### Forms & inputs (Phase 3)

- `FwField` shell + typed field state (`F01`).
- Text inputs: `FwTextField`, `FwTextArea`, `FwSearchField` (`F02/F03/F12`).
- Selection inputs: `FwCheckbox`, `FwRadio`, `FwSwitch`, `FwSelect`,
  `FwMultiSelect` (`F04–F08`).
- `FwSlider` + expansion (`F09`).
- New inputs: OTP, rating, phone (`F22/F21+/F23`).
- Feedback: `FwAlert`, `FwLinearProgress`/`FwCircularProgress`,
  `FwSkeleton`, `FwStatePanel` (`B01/B03–B07`).
- Form recipes: registration, settings, error summary (`P3.7`).

### Overlays, pickers, notifications (Phase 4)

- Dialogs, confirmations, bottom sheets, drawers, popovers, menus
  (`O01–O04`, `O06/O07`).
- Pickers and advanced inputs: date/time, color, file, autocomplete
  (`F10/F11/F13–F16`).
- Toast service (`FwToast`/`FwToastHost`) (`B02`), task progress list
  (`B08`), notification center (`B11`).
- Event-scheduling recipe (`P4.6`).

### Navigation & adaptive structure (Phase 5)

- Action buttons: button group, segmented control, split button
  (`A04–A06`); copy action, slide-to-confirm, hold-to-confirm
  (`A09–A11`).
- Navigation core: tabs, navbar, sidebar, breadcrumb (`N01–N04`);
  pagination, stepper, bottom nav, rail (`N05–N08`) — one selection model.
- Adaptive layout + onboarding flow (`L08–L10/L12`, `R01`).
- Dashboard + master-detail recipes (`P5.6`).

### Data display & media (Phase 6)

- Text display: rich text, quotes/lists, code/kbd (`T02/T07/T08`).
- Media: `FwFigure`, `FwAvatarGroup` (`M02/M04`).
- `FwStatusDot` (`B09`), `FwAccordion` (`D03`), data table (`D04`),
  responsive cards (`D05`), timeline (`D07`).
- Researched additions: carousel, photo viewer, swipeable, refreshable
  list, stat (`P6.5`).
- Searchable/paginated data page recipe (`P6.6`).

### Documentation, pilots, release (Phase 7)

- Full `docs/` tree: start guides, design system, theming, layout,
  components (~85 IDs), forms, quality, reference, migration
  (`P7.1`); docs link-check test guarantees every `Fw*` identifier in
  docs exists in code.
- Three pilot apps on public exports only — settings/forms,
  dashboard/data, marketing/content — each with widget tests (`P7.2`).
- Pilot-driven defect fix: `FwToastHost` in `MaterialApp.builder` (the
  documented placement) no longer crashes — dismiss button is now a
  bounded, semantics-labeled `IconButton` (Material `Tooltip` requires an
  `Overlay` ancestor absent above the `Navigator`, and explodes to
  100000px under unbounded height).
- Integration notes: platform feasibility (web validatable here),
  dependency graph, `fw_layout` → `fw_components` layering exception
  (`P7.3`).

## 0.1.0 — Foundation

- Design-system foundation: `DS-01`–`DS-12` (units, spacing, type, color,
  density, motion, shapes/shadows, scopes, presets, migration, docs).
- Component catalog foundation: action system (`A01/A02/A07`), text
  primitives (`T01/T03–T06`, `A03`), layout primitives (`L03–L07`), media
  primitives + tooltip (`M01/M03/M05`, `O05`), display primitives
  (`D01/D02`).
- Package structure: `fw_core`, `fw_layout`, `fw_utilities`,
  `fw_components`, umbrella `fw`; gallery app.

## Versioning

All framework packages (`fw`, `fw_core`, `fw_layout`, `fw_utilities`,
`fw_components`) are versioned together. Pre-1.0 semver:

- Patch (`0.1.x`): bug fixes, no API change.
- Minor (`0.x.0`): new features, new components, new tokens. May include
  breaking changes to unreleased APIs, documented in the changelog.
- Major (`1.0.0`): first stable release. After 1.0, semver is strict.

## Deprecation policy

- Public APIs are never removed in a patch release.
- Deprecations are announced with a `@deprecated` annotation naming the
  replacement, and the API is removed no earlier than the next minor
  release (pre-1.0) / next major release (post-1.0).
- Token renames keep the old key as an alias for one minor release cycle
  with a migration note in `docs/migration.md`.
