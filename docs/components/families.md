# Component families

Family-level contracts. For the per-component five-board documentation,
see the gallery app (`apps/gallery`) — every component below has an
interactive board there.

## Actions

Buttons separate **visual variant** from **semantic intent**: a destructive
action is a solid danger button, not a red-styled primary.

```dart
FwButton(
  label: 'Delete',
  variant: FwButtonVariant.solid,
  intent: FwIntent.danger,
  onPressed: _delete,
)
```

- `FwButtonVariant`: solid, outline, ghost, link, tonal.
- `FwIntent`: primary, neutral, success, warning, danger, info.
- `leading` / `trailing` icon slots with token spacing; `FwButton.icon`
  for icon-only (requires a semantic label; ≥ 48dp target).
- `loading` shows progress and blocks re-entry; busy and disabled buttons
  never invoke `onPressed`.
- `FwIconButton`, `FwCloseButton` share the intent system.
- Groups: `FwButtonGroup` (A04), `FwSegmentedGroup` (A05), `FwSplitButton`
  (A06) — single selection model, shared disabled semantics.
- `FwCopyAction` (A09) copies to clipboard with confirmation feedback.
- Gesture confirmations: `FwSlideToConfirm` (A10) and `FwHoldToConfirm`
  (A11) — drag threshold / press-and-hold progress, haptic feedback,
  and **always a non-gesture alternative** (a plain button) for keyboard,
  switch-access, and reduced-motion users.

Keyboard: buttons activate on Enter/Space; focus ring is always visible.
Unsupported: using color alone to signal intent; gesture-only activation.

## Text

- `FwText(data, role: FwTextRole.h1)` — role-based type; `heading: true`
  for screen-reader heading structure.
- `FwLink` — text link with the five-state matrix
  (default/hover/focused/pressed/disabled).
- `FwBadge`, `FwChip`, `FwDivider` — counts, tags, and separators with
  variant × state boards.
- `T02` rich text, `T07` quotes & lists, `T08` code & keyboard — semantic
  text compositions that stay inside the role system.

## Media

- `FwImage` — responsive image with aspect reservation (no layout shift),
  loading/error slots, and decode/cache policy.
- `FwAvatar` / `FwAvatarGroup` — initials/image with fallback chain.
- `FwIcon` — icon with the 16/20/24 size tokens.
- `FwCarousel` (M09) with page indicators; `FwPhotoViewer` (M07+) with
  zoom gestures.
- `FwFigure` (M02) — captioned media.

CORS/offline/error handling is the app's policy; the widgets expose the
slots. See [media](../media.md).

## Data display

- `FwCard` / `FwInteractiveCard` (D01) — slot-based surfaces.
- `FwListTile` / `FwList` (D02), `FwAccordion` (D03).
- `FwDataTable<T>` (D04) — sort/filter/paginate/select/expand; start with
  small data and publish collection limits before virtualizing.
- `FwStat` (D06), `FwTimeline` (D07).
- `FwSwipeable` (D10) — swipe actions with a non-gesture alternative.

Mobile presentation is a deliberate contract: tables reflow to cards or
horizontal scroll; every essential field and row action must be reachable
on phones.

## Layout

`FwVStack`/`FwHStack` (L03), `FwWrap` (L04), `FwAutoGrid` (L05),
`FwShow`/`FwResponsiveBuilder` (L06), scroll areas (L08), adaptive
scaffold (L09), master-detail (L10), sliver adapters (L12). See the
[Layout section](../layout/containers.md).

## Forms

All inputs sit in the `FwField` shell (F01): label, helper, error layout
with typed field state.

- Text: `FwTextField` (F02), `FwTextArea` (F03), `FwSearchField` (F12),
  `FwPasswordField` (F04, reveal toggle + strength bar),
  `FwNumberField` (F11), `FwCombobox` (F13).
- Selection: `FwCheckbox` (F05, tri-state), `FwRadioGroup` (F06),
  `FwSwitch` (F07), `FwSelect` (F08), `FwMultiSelect` (F14).
- Sliders: `FwSlider` (F09, drag vs commit semantics), `FwRangeSlider`
  (F10).
- Pickers: `FwDateField` (F15), `FwTimeField` (F16) — field wrappers
  around token-adapted native pickers.
- Special: `FwOtpInput` (F22, per-box with paste + `oneTimeCode`
  autofill), `FwRatingInput`/`FwRatingDisplay` (F21), `FwPhoneField`
  (F23, country picker + dial-code hooks).

Controllers are caller-owned; validation timing (on change / on blur /
on submit) is explicit per field. See [Forms](../forms/lifecycle.md).

## Feedback

- `FwAlert` (B01), `FwLinearProgress`/`FwCircularProgress` (B03), `FwSkeleton`
  (B06, reduced-motion safe), `FwStatePanel` (B07: loading/error/empty),
  `FwStatusDot` (B09), `FwRefreshableList` (B10: pull-to-refresh +
  infinite scroll), `FwTaskList` (B08).
- `FwToast` (B02) — queued toasts with action/undo, swipe-dismiss, and a
  context-free `FwToast.show()` API. The app places `FwToastHost` once
  (above the navigator).
- `FwNotificationCenter` (B11) — grouped in-app notifications with unread
  badges, mark-read/clear, deep-link callbacks owned by the app.

## Overlays

- `FwDialog` (O01) / `FwConfirmDialog` (O02) — focus-trapped, with a busy
  dismiss-lock for async saves.
- `FwSheet` (O03) — drag handle, snap points, modal/modeless.
- `FwDrawer` (O03), `FwPopover` (O04, anchored with flip logic),
  `FwTooltip` (O05), `FwMenu` (O06, keyboard nav + submenus),
  `FwContextMenuRegion` (O07).

All overlays consume `FwElevation` tokens and honor reduced motion.

## Navigation

One shared selection model (`FwDestination` ids) drives every form
factor — never duplicate selection state per widget.

- `FwTabs` (N01), `FwNavbar` (N02), `FwSidebar` (N03), `FwBreadcrumb`
  (N04), `FwPagination` (N05), `FwStepper` (N06: skippable steps,
  validation gating, `controlsBuilder`), `FwBottomNavigation` (N07),
  `FwNavigationRail` (N08).
- `FwOnboardingFlow` (R01) — intro sequences with skip/complete.

Route contracts are callback-based and route-neutral; the app owns the
router. See [adaptive panes](../layout/adaptive.md).
