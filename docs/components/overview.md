# Component catalog

Every component follows the five-board documentation contract —
**Anatomy**, **Properties** (variants × states), **Layout & spacing**,
**Usage** (do / don't), **Accessibility** — with interactive versions in
the gallery app (`apps/gallery`), organized in atomic tiers:
Foundations → Atoms → Molecules → Organisms → Patterns.

## Spacing convention (improvement-plan-2 P2.5)

**The container owns the gap.** Spacing between siblings is declared on the
container — `FwHStack`/`FwVStack`/`FwInline`/`FwWrap` `gap`, or a one-off
`FwGap` — never as `margin:` on children. Margins collapse unpredictably,
break reordering, and fight the density system; container gaps compose.

- Padding *inside* a component uses `FwBox` (logical props) or a spacing
  token via `FwSpaceScale.of` / `FwSpaceScale.resolveAlias`.
- Every `EdgeInsets`, `SizedBox`, `BorderRadius`, `spacing:`/`runSpacing:`,
  and `margin:` literal in `lib/src` must resolve a token (`FwSpace`,
  `FwSpaceAlias`, `FwRadii`, `FwRadiusClasses`) — enforced by the
  `no_hardcoded_spacing` discipline test, which also flags `margin:` with
  raw values. The only way to add a literal is a documented exemption with
  a reason (control heights, paint-level geometry).
- New components: reach for `FwGap`/`FwBox`/`FwInline` before hand-rolling
  a `Row` + `SizedBox` or a `Padding` with physical insets.

## Index

| ID | Component | Tier |
|---|---|---|
| A01 | Button | Atoms |
| A02 | Icon button | Atoms |
| A03/T03 | Link | Atoms |
| A04 | Button group | Molecules |
| A05 | Segmented group | Molecules |
| A06 | Split button | Molecules |
| A07 | Close button | Atoms |
| A09 | Copy action | Molecules |
| A10 | Slide to confirm | Molecules |
| A11 | Hold to confirm | Molecules |
| T01 | Text | Atoms |
| T02 | Rich text | Molecules |
| T04 | Badge | Atoms |
| T05 | Chip | Atoms |
| T06 | Divider | Atoms |
| T07 | Quote & lists | Molecules |
| T08 | Code & keyboard | Molecules |
| M01 | Image | Molecules |
| M02 | Figure | Molecules |
| M03 | Avatar | Atoms |
| M04 | Avatar group | Molecules |
| M05 | Icon | Atoms |
| M07+ | Photo viewer | Molecules |
| M09 | Carousel | Molecules |
| D01 | Card | Molecules |
| D02 | List tile / List | Molecules |
| D03 | Accordion | Molecules |
| D04 | Data table | Organisms |
| D06 | Stat | Molecules |
| D07 | Timeline | Molecules |
| D10 | Swipeable | Organisms |
| L03 | Stacks | Molecules |
| L04 | Wrap | Molecules |
| L05 | Auto-fit grid | Molecules |
| L06 | Show / responsive builder | Molecules |
| L08 | Scroll area | Molecules |
| L09 | Adaptive scaffold | Organisms |
| L10 | Master-detail | Organisms |
| L12 | Sliver adapters | Molecules |
| F01 | Field shell | Molecules |
| F02 | Text input | Molecules |
| F03 | Textarea | Molecules |
| F04 | Password field | Molecules |
| F05 | Checkbox | Molecules |
| F06 | Radio group | Molecules |
| F07 | Switch | Molecules |
| F08 | Select | Molecules |
| F09 | Slider | Molecules |
| F10 | Range slider | Molecules |
| F11 | Number field | Molecules |
| F12 | Search field | Molecules |
| F13 | Combobox | Molecules |
| F14 | Multi-select | Molecules |
| F15 | Date field | Molecules |
| F16 | Time field | Molecules |
| F21 | Rating | Molecules |
| F22 | One-time-code input | Molecules |
| F23 | Phone field | Molecules |
| B01 | Alert | Molecules |
| B02 | Toast | Molecules |
| B03 | Progress | Molecules |
| B06 | Skeleton | Molecules |
| B07 | State panel | Molecules |
| B08 | Task list | Molecules |
| B09 | Status dot | Molecules |
| B10 | Refreshable list | Molecules |
| B11 | Notification center | Organisms |
| O01 | Dialog | Organisms |
| O02 | Confirmation dialog | Organisms |
| O03 | Bottom sheet / Drawer | Organisms |
| O04 | Popover | Organisms |
| O05 | Tooltip | Atoms |
| O06 | Menu | Organisms |
| O07 | Context menu | Organisms |
| N01 | Tabs | Molecules |
| N02 | Navbar | Organisms |
| N03 | Sidebar | Organisms |
| N04 | Breadcrumb | Molecules |
| N05 | Pagination | Molecules |
| N06 | Stepper | Molecules |
| N07 | Bottom navigation | Organisms |
| N08 | Navigation rail | Organisms |
| R01 | Onboarding flow | Organisms |

## Family pages

- [Actions](families.md#actions) — A01–A11: buttons, groups, split, copy, gesture confirmations
- [Text](families.md#text) — T01–T08: text, rich text, badge, chip, divider, quote, code
- [Media](families.md#media) — M01–M09: image, figure, avatar, icon, photo viewer, carousel
- [Data display](families.md#data-display) — D01–D10: card, lists, accordion, data table, stat, timeline, swipeable
- [Layout](families.md#layout) — L03–L12: stacks, wrap, grids, builders, scroll, adaptive, master-detail, slivers
- [Forms](families.md#forms) — F01–F23: field shell, inputs, selection, sliders, pickers, OTP, rating, phone
- [Feedback](families.md#feedback) — B01–B11: alert, toast, progress, skeleton, state panel, tasks, status, refresh, notifications
- [Overlays](families.md#overlays) — O01–O07: dialog, sheet, drawer, popover, tooltip, menu, context menu
- [Navigation](families.md#navigation) — N01–N08, R01: tabs, navbar, sidebar, breadcrumb, pagination, stepper, bottom nav, rail, onboarding

Each family page covers: purpose and when *not* to use it, the smallest
compilable example, essential properties and ownership, variants/sizes/
states, theme customization, responsive and root behavior, keyboard map,
semantics and localization expectations, controller/async lifecycle,
failure/empty/loading cases, platform limits, related components, and
explicitly unsupported behavior.
