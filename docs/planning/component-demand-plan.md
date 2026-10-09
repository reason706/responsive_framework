# Component demand plan (research-backed)

Date: 2026-10-09. Source: deep research over pub.dev demand signals
(likes/downloads), Flutter Q2 2026 survey (3,500+ responses), shadcn/ui as
web-demand proxy, production app manifests. Full notes:
`~/workspace/research_notes/flutter-component-demand-research-20261009-0221/`.

This plan proposes additions and improvements to the catalog in
`components.md` / `delivery.md`. IDs prefixed `+` are new; others are
promotions or scope changes to existing IDs.

## Top-10 additions (priority order)

| # | ID | Component | Why (demand evidence) | Proposed phase |
| --- | --- | --- | --- | --- |
| 1 | +F22 | OTP/PIN input | pinput: 3.48k likes, 541k downloads; zero framework support; auth/2FA in nearly every consumer app | Phase 3 (forms) |
| 2 | +D10 | Swipeable list actions | flutter_slidable: 6.13k likes, Flutter Favorite; Dismissible only covers full-swipe, not action panes | Phase 6 (display) |
| 3 | +M09 | Image carousel + page indicators | carousel_slider 6.04k likes, smooth_page_indicator 4.09k; e-commerce, promos, onboarding | Phase 6 (media) |
| 4 | +B10 | Pull-to-refresh + infinite scroll | pull_to_refresh 2.83k likes despite stale since 2021; infinite_scroll_pagination 4.05k likes; RefreshIndicator alone doesn't satisfy | Phase 3 (feedback) |
| 5 | +F23 | Phone-number field + country picker | 781 likes across fragmented forks; auth/onboarding critical path, no canonical widget | Phase 3 (forms) |
| 6 | F15+ | Inline calendar / date-range picker | Built-in showDatePicker is dialog-only; syncfusion picker 1.64k likes (verified live); promote F17 from 1.x, add inline mode | Phase 4 (forms) |
| 7 | +R01 | Onboarding/intro flow scaffold | introduction_screen 2,650 likes; every consumer app ships one, everyone rebuilds it | Phase 7 (recipes) |
| 8 | M07+ | Zoomable photo viewer | In real production manifests; promote from 1.x: pinch-zoom, double-tap, hero transitions | Phase 6 (media) |
| 9 | F21+ | Rating bar (input + display) | In production manifests; promote from 1.x; e-commerce/reviews staple | Phase 3 (forms) |
| 10 | L09+ | Adaptive navigation shell | Official flutter_adaptive_scaffold discontinued (flutter/flutter#162965); own bottom-nav ↔ rail ↔ drawer by M3 width classes | Phase 5 (navigation) |

Next tier: +T09 read-more/expandable text, +M10 cached-image contract
(disk+memory cache, BlurHash placeholders — answers cached_network_image's
6.93k-like demand inside M01), +D11 tree view (promote D08), web/desktop set
below, +M11 markdown rendering.

## Gesture confirmations, sliders, toasts, notifications

High-demand interaction patterns that deserve first-class components:

| ID | Component | Why |
| --- | --- | --- |
| +A10 | Slide to confirm / slide to unlock | action_slider (420 likes), slide_to_act (269), slide_to_confirm (150) — fragmented, no canonical widget. Fintech "slide to pay", ride apps, unlock flows. Needs drag thumb + threshold, loading/success/failure states (action_slider's controller pattern), RTL support, and a keyboard/switch-access alternative — a gesture must never be the only path. |
| +A11 | Hold to confirm | Press-and-hold with progress fill for destructive/irreversible actions (delete, wipe, payments). hold_to_confirm_button exists but is tiny and stale; pair with haptic feedback (light on start, heavy on confirm) and the same non-gesture fallback as A10. |
| F09+ | Slider expansion | Built-in Slider is thin: add circular slider (sleek_circular_slider: 1.37k likes), vertical orientation, custom thumbs/tracks, discrete tick marks, value bubbles. Promote the 1.x "custom discrete marks" scope into 1.0. |
| B02+ | Toast expansion | fluttertoast 3,672 likes; toastification 173k monthly users. Beyond the planned B02: queueing, de-duplication, stacking (max 3), top/center/bottom placement, action buttons (Undo), swipe-to-dismiss, context-free invocation, rich content. |
| +B11 | Notification center | Nearly every consumer app has an in-app notification list: unread badges, grouping, mark-read/clear, empty state, deep-link to content. Push delivery is platform work (flutter_local_notifications); the *list UI* is the framework gap. Compose FwListTile + FwBadge + B07 empty state. |

A10/A11 share one accessibility contract: every gesture confirmation ships
with an equivalent non-gesture control (button or checkbox + button), and
reduced-motion users get instant state changes without the drag animation.

## Improvements to already-planned components

- **Forms (F01–F16):** adopt flutter_form_builder/reactive_forms lessons —
  declarative validators, async validation, conditional field visibility,
  dirty/touched tracking, wizard support, per-field errorBuilder theming
  (pinput's API shape). Ship a form controller, not just fields.
- **Date pickers (F15/F16):** inline calendar mode, single/range/multi
  selection, event markers, locale handling (table_calendar pattern).
- **Data tables (D04):** build table→cards reflow below ~600dp into the
  component; sticky headers; column visibility by breakpoint.
- **Skeletons (B06):** copy skeletonizer's trick — generate bones from the
  real widget tree instead of hand-maintained shimmer duplicates.
- **Bottom sheets (O03):** drag-to-dismiss with velocity, iOS-style
  presentation, nested navigation (modal_bottom_sheet pattern).
- **Toasts (B02):** queueing, de-duplication, stacking, action buttons,
  swipe-to-dismiss, context-free invocation.
- **Stepper (N06):** validation-gated wizards; Flutter's Stepper is weak —
  add skippable steps and step indicators.
- **Cupertino parity:** Q2 2026 survey puts Cupertino widgets at 61%
  satisfaction (lowest, down 6pts). Every component above should ship an
  iOS-styled variant, not just Material.

## Mobile-vs-web guidance

- Mobile-heavy: pull-to-refresh, swipe actions, drag-to-close sheets, OTP
  SMS autofill, share sheet (recipe), onboarding carousels, infinite feeds,
  pinch-zoom.
- Web/desktop-heavy: data tables with sort/filter, hover states + hover
  cards, keyboard shortcuts, ⌘K palette (X05 covers), right-click menus,
  menubar, resizable panes — shadcn parity items missing from the catalog.
- Adaptive rule: branch on available width (M3 classes: <600 bottom nav,
  600–840 rail, 840–1200 extended rail, ≥1200 drawer), never on device type.

## Caveats

Like counts for some packages come from index snapshots (Feb–Sep 2026);
only date-picker numbers were verified live on 2026-10-09. share_plus
demand (3.99k likes) is real but it's a platform plugin — recipe-level, not
framework scope.

## NoNameYet case study findings (images read directly, 2026-10-09)

Source: behance.net/gallery/214426497 (Anna Remesnyk, Dec 2024). All 19
image modules extracted and the key six read in full. Concrete patterns:

- **Token naming**: `$spacing-4` … `$spacing-160`, named by px value with
  rem + px columns side by side. 8px scaling method with a 4px exception
  for the smallest gaps. (Our t-shirt naming `s0..s24` is a valid
  alternative; document the choice and keep the 4px exception.)
- **Atomic tiers in practice**: atoms (colors, typography, buttons, inputs,
  icons) → molecules (form fields, navigation items, cards) → organisms
  (headers, product cards) → templates (dashboards, forms, homepages) →
  pages. Adopt this tiering for catalog organization (gap #12).
- **Component documentation contract** (the strongest takeaway): every
  component ships three boards — **Anatomy** (annotated callouts with
  exact measurements), **Properties** (Type variants × State matrix:
  Default/Hover/Focused/Pressed/Disabled), **Layout and spacing**
  (selected-node specs: padding, item spacing, direction, alignment,
  resizing behavior). Make this the per-component doc template (gap #8).
- **Button intents as variants**: Primary / Secondary / Tertiary /
  Icon Only / Constructive (green) / Modal (red) — validates separating
  visual variant from semantic intent (our A01 approach).
- **Selection state matrices**: checkbox unchecked/checked/indeterminate ×
  5 states; radio unselected/selected × 5 states; dropdown with error
  state ("This field is required") — validates F05/F06/F08 scope.
- **Iconography**: Material Design Icons, three sizes (16/20/24px) —
  validates M05 size tokens; prefer a typed icon set over raw IconData
  (gap #2).
