# Component catalog and implementation contracts

This is a proposed backlog, not an inventory of implemented widgets. Names are
provisional. `MVP` means first usable release and also required for 1.0; `1.0`
means required before stable release; `1.x` is deferred; `Adapter` is optional.
Existing button/card/container/grid implementations must be extended to these
contracts rather than counted as already complete.

## 1. Shared rules for every component

Every applicable component gets typed theme defaults, explicit override
precedence, directional layout, content-driven sizing, semantic labels/roles,
keyboard/focus behavior, and a documented state model. Controllers supplied by
the caller remain caller-owned. Internal controllers/subscriptions are disposed
by the widget and reconciled correctly when its configuration changes.

Each component has a gallery page, minimal example, customization example,
responsive/large-text example, state examples, API documentation, meaningful
behavior tests, and representative visual regression cases. A screenshot of its
default state does not prove focus, validation, or loading behavior.

Public callbacks describe user intent; components do not embed backend URLs,
authentication, application routing, storage, or a particular state manager.
Use native Flutter primitives where they provide robust behavior. Wrap with
framework tokens and documented semantics rather than rebuilding text editing,
gesture arenas, focus traversal, or scrolling without a demonstrated need.

Sizes/variants are shared vocabulary, not a requirement to support every size
and color on every widget. The theme defines metrics; responsive widths/spacing
are allowed where they make sense. Booleans and arbitrary data are not turned
into responsive props merely for API symmetry.

## 2. Buttons and actions

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| A01 | Button — MVP, extend existing | Solid, outline, ghost, link; semantic intent; sm/md/lg; leading/trailing icon; busy, disabled, focused | Retain Material activation/focus. Separate visual variant from intent. Use token padding/min-content height, localized busy label and optional indicator. Caller controls busy state. |
| A02 | Icon button — MVP | Filled/tonal/outline/ghost; icon size; selected toggle option; disabled/busy | Build on IconButton; require accessible name/tooltip policy; maintain >=48 target even when glyph is small. |
| A03 | Action link — MVP | Inline/standalone, external destination cue, visited styling only if app supplies state | Separate navigation from submit/action callbacks. Underline or another tested non-color cue; URI handling delegated to application/optional launcher adapter. |
| A04 | Button group — 1.0 | Horizontal/vertical, attached/spaced, wrap-to-stack on narrow width | Compose buttons with shared shape/border rules and no doubled seams. Preserve source/focus order. |
| A05 | Toggle / segmented group — 1.0 | Single/multiple choice, required/optional selection, icon+label | Use typed values and controlled selection. Define arrow-key behavior, roving focus where appropriate, disabled items and selected semantics. |
| A06 | Split button — 1.0 | Primary action plus independently named menu trigger | Compose A01+A02+O06; distinct touch targets and focus stops. Menu opening never invokes primary action. |
| A07 | Close/dismiss action — MVP | Standard close glyph, localized name, optional destructive context | Thin icon-button specialization; parent owns dismissal. Clear hover/focus and consistent target. |
| A08 | Floating action button / speed dial — 1.x | Extended/compact; expandable actions | Optional advanced composition after overlays. Respect safe areas and avoid covering critical content; speed dial needs full focus/escape behavior. |
| A09 | Copy action — 1.0 | Idle/copying/copied/error feedback | Clipboard callback/interface, bounded feedback duration, localized status announcement. No clipboard permission assumptions or secret logging. |

Button implementation sequence: expand styles/states first; add icons/sizing;
extract shared action metrics; add icon action and link; then groups/toggles;
add split buttons only after the menu layer is tested.

Unique proof: keyboard Enter/Space activates once; busy/disabled never invokes
callbacks; menu and primary split actions stay distinct; long labels grow/wrap;
groups preserve focus order when wrapping; asynchronous copy completion never
updates disposed state. No essential meaning conveyed only by button color.

## 3. Text and small content primitives

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| T01 | Text and heading — MVP | Body/lead/caption/display/h1–h6, selectable option, wrapping and explicit truncation | Resolve typography tokens into Text/SelectableText. Heading semantics separate from visual size; text scale inherited once. |
| T02 | Rich text — 1.0 | Inline styles, links, emphasized text, code spans | RichText/TextSpan with inherited theme/scaler. Own and dispose gesture recognizers where needed; selectable mode is a documented separate rendering path. |
| T03 | Link — MVP | Inline, icon link, disabled only with explicit semantics | Share A03 behavior; one link/navigation implementation, not duplicate incompatible APIs. |
| T04 | Badge — MVP | Solid/subtle/outline; intent; count, dot, overflow label | Noninteractive by default. Provide accessible full count when visual text is `99+`; allow clear distinction from interactive chip. |
| T05 | Chip/tag — MVP | Assist/filter/input; leading icon/avatar, selected, removable, disabled | Use Flutter Chip primitives where suitable. Selection and removal are separate callbacks and semantic actions. |
| T06 | Divider — MVP | Horizontal/vertical, inset, label-separated | Token border/spacing; mark decorative dividers appropriately. Vertical layouts need bounded height; no intrinsic-layout surprise by default. |
| T07 | Quote and ordered/unordered list — 1.0 recipe | Citation, nested items, directional marker, long content | Compose typography and layout helpers. Publish recipes first; add public widgets only if shared behavior justifies them. |
| T08 | Keyboard shortcut / inline code / code block — 1.0 | Key combination, monospace, wrap or horizontal scroll, copy action | Tokenized surfaces/type; code escaping preserved. Syntax highlighting is optional adapter work, not core parsing. |

Unique proof: visual heading role can differ from semantic level deliberately;
rich text retains scaler and focusable links; noninteractive badge is not a
button; chip removal works with keyboard/semantics; code can be selected/copied
without losing literal formatting. Long translated text is part of examples.

## 4. Layout primitives and adaptive composition

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| L01 | Container — MVP, extend existing | Fixed/fluid/custom max, responsive directional insets | Migrate padding/max-width expressions to typed metrics. Width measured before max constraint; content scope measures actual inner width. |
| L02 | Row/column grid — MVP, extend existing | 12-column spans, responsive horizontal/vertical gutters, nested rows | Keep tested Wrap math initially. Add typed gap resolution. Defer auto spans/offsets until line-placement rules are documented; custom render object only if needed. |
| L03 | HStack/VStack/adaptive stack — MVP | Gap, alignment, responsive horizontal→vertical change | Compose Flex/Column/Row; no Expanded inserted under an invalid parent. Provide explicit flexible child policy and bounded-main-axis requirements. |
| L04 | Wrap — MVP | Directional alignment, gap/run gap | Theme-aware Wrap facade; preserves source and focus order. |
| L05 | Auto-fit responsive grid — MVP | Minimum item width, maximum columns, aspect ratio option | Compute columns from bounded width/gap; use lazy GridView/slivers for large collections. Preserve stable item keys on resize. |
| L06 | Show/hide/responsive builder — MVP | Width ranges, remove vs retain state | Explicit hidden-state policy. Hidden children must not remain unexpectedly focusable or visible to semantics; retained state has documented cost. |
| L07 | Aspect ratio / constrained box / spacer — MVP | Ratios, rem limits, flexible remaining space | Wrap native primitives with typed constraints. Ratios must be positive; intrinsic dimensions and unbounded axes are documented. |
| L08 | Scroll area — 1.0 | Vertical/horizontal, scrollbars, keyboard scrolling | Native ScrollView/Scrollbar composition with caller controller ownership. Respect platform scroll behavior; no forced nested scrolling traps. |
| L09 | Adaptive scaffold — 1.0 | Bottom navigation → rail → persistent sidebar; header/actions | Share one typed navigation model and preserve selected destination across transitions. Platform safe areas and keyboard insets included. |
| L10 | Master-detail / dashboard shell — 1.0 recipe | Stacked mobile, split wide, deep-link-aware selected detail | Compose scaffold and responsive panes. Application supplies routing; preserve pane scroll/state and mobile back behavior. |
| L11 | Resizable splitter — 1.x | Horizontal/vertical, min/max, persistence callback | Constraint-aware pointer/keyboard resizing; external state, accessible separator value and controls. No desktop-only assumptions. |
| L12 | Sliver section adapters — 1.0 | Padded section, sticky-header composition, lazy grids/lists | Small adapters for CustomScrollView; avoid nesting shrink-wrapped grids inside long pages. Sticky headers need overlap and semantics tests. |

Grid safeguards: define total-width accounting, shrink gutters at very narrow
widths, verify full spans do not wrap from floating-point errors, and reject
invalid spans even when an override is inactive. Decide whether offsets are
empty grid tracks or physical insets before exposing them.

Unique proof: parent width differs from viewport width; changing breakpoints
does not lose text-field state; large collections build lazily; hidden controls
leave focus/semantics correctly; fixed/max sizing does not overflow phone widths.
SafeArea, keyboard `viewInsets`, text scale, and scroll position are tested in
page recipes rather than inferred from a static grid test.

## 5. Images, avatars, icons, and media

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| M01 | Responsive image — MVP | Asset/network/memory via ImageProvider; contain/cover; rounded/thumbnail; loading/error; decorative/meaningful | Wrap Image with explicit constraints and aspect-ratio reservation. Permit placeholders/error builder; caller supplies provider and accessible label. Do not depend on `dart:io` in the cross-platform core. |
| M02 | Figure — 1.0 | Image + caption + optional credit/action | Compose M01+T01; caption may wrap independently. Avoid duplicate announcement of identical image/caption text. |
| M03 | Avatar — MVP | Image/initials/icon fallback; circle/rounded; sizes; status badge | Fixed bounded token diameter; ImageProvider fallback. Initials strategy uses grapheme clusters or caller-provided initials, not naive string indexing. Status has text meaning. |
| M04 | Avatar group — 1.0 | Overlap, capped visible count, `+N`, ordering | Compose avatar visuals; preserve underlying names/semantic list and optional overflow action. Overlap never makes required actions inaccessible. |
| M05 | Icon — MVP | Size, role color, decorative/meaningful, optional leading icon | Use IconData/Widget slots; avoid forcing a vendor icon pack. Interactive behavior belongs to A02. |
| M06 | Carousel — 1.x | Swipe, keyboard, indicators, controlled page, autoplay opt-in | PageView-based behavior; stable page state, pause when obscured/unfocused, reduced-motion respect. Autoplay is never default. |
| M07 | Image viewer / lightbox — 1.x | Zoom/pan, gallery index, escape/close, restoration | Overlay+InteractiveViewer; gesture conflict, image decode memory, focus restoration, and accessibility alternatives need dedicated work. |
| M08 | SVG support — Adapter | Asset/network SVG; semantic label; sizing parity | Choose a maintained Flutter SVG package, keep optional, and test asset trust/supported features. No HTML injection or JS plugin bridge. |

### Image and avatar pipeline

1. Define source/provider, semantic purpose, fit, reserved dimensions, fallback.
2. Resolve rem/pixel dimensions and parent max width without distorting ratio.
3. Prefer decoding near rendered physical dimensions when the provider supports
   it; account for DPR once and cap large allocations.
4. Preserve layout while loading or failing. A failed image must not collapse a
   card unexpectedly or trigger infinite automatic retries.
5. Expose optional cache policy through an adapter; retain Flutter's normal
   image-cache behavior unless profiling justifies more.
6. Document web CORS, expiring URLs, offline assets, and image-provider limits.
7. Test providers with deterministic fakes; do not depend on live image URLs in CI.

Unique proof: error and loading states reserve the same geometry; responsive
images never exceed parent width; labels announce once; initials handle emoji
and multi-code-point names; interactive avatar groups provide usable targets.

## 6. Forms and input controls

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| F01 | Form field shell — MVP | Label, required hint, description, helper/error, prefix/suffix, read-only/disabled | Shared `FormField<T>` integration and field theme. Persistent visible label; field decoration independent from value editor. |
| F02 | Text input — MVP | Filled/outline; keyboard type; autofill; formatters; prefix/suffix; clear action | TextFormField/EditableText primitives. Caller controller vs internal controller rules, cursor/composition preservation, reset/save and focus ownership. |
| F03 | Textarea — MVP | Min/max lines, expandable within bounded region, character counter | Multi-line native editing; no unbounded fixed height. Counter policy handles grapheme length and localized remaining count. |
| F04 | Password input — MVP | Reveal toggle, autofill/password manager, optional strength presentation | F02 plus named icon action. Preserve selection/focus while toggling. Strength estimator is optional, never claimed as a security guarantee. |
| F05 | Checkbox / checkbox group — MVP | Checked/unchecked/indeterminate; description/error; group values | Native checkbox with merged appropriate label semantics. Group supports typed IDs and validation, not hard-coded string values. |
| F06 | Radio group — MVP | Single required/optional value, layout wrap/stack | Shared controlled group; keyboard traversal and disabled options. Use appropriate selected-value semantics. |
| F07 | Switch — MVP | On/off, description, disabled/busy | Native Switch with field label. Distinguish immediate setting change from submit-form choice; asynchronous state is caller-controlled. |
| F08 | Simple select — MVP | Typed options, placeholder, selected/disabled item, error | Build on suitable native DropdownMenu/FormField behavior; define equality/stable option keys. Small option sets only; no remote fetch embedded. |
| F09 | Slider — MVP | Min/max, continuous/discrete, value label/unit, disabled, focus | Wrap native Slider/SliderTheme. Separate `onChanged` from commit/end callback. Validate bounds, format localized accessible values. |
| F10 | Range slider — 1.0 | Two endpoints, step, formatted range, min/max | Native RangeSlider; keep ordered endpoints and distinguish the two semantic handles. Document RTL and key-step behavior. |
| F11 | Number input / stepper — 1.0 | Increment/decrement, min/max/step, decimal/locale, empty/null | Text input+icon actions. Define rounding/precision and invalid intermediate text. No coercion while IME composition is active. |
| F12 | Search field — MVP | Search icon, clear, loading/empty affordance, submit callback | F02 specialization with callbacks; debounce is a caller option/service, not a hidden network operation. |
| F13 | Combobox / autocomplete — 1.0 | Local/async suggestions, keyboard active option, no results/loading/error | Shared anchored listbox; controlled query/selection. Debounce/cancellation or sequence IDs prevent stale results overwriting a new query. |
| F14 | Multi-select — 1.0 | Tags, search/filter, selected summary, max selection, disabled options | Shared selection/listbox logic with typed stable IDs; chip removal, keyboard traversal, and large-text wrap behavior. |
| F15 | Date field / picker — 1.0 | Locale format, min/max, disabled dates, calendar and typed input | Start with supported Flutter date picker adapted to tokens. Treat civil dates separately from UTC timestamps; custom full calendar is later work. |
| F16 | Time field / picker — 1.0 | 12/24h, locale, allowed range, typed input | Native time picker adapter plus field shell. A wall-clock time has no timezone until the application assigns one. |
| F17 | Date-range picker — 1.x | Start/end, presets, disabled intervals | Reuse date foundation; keyboard navigation and locale/week-start behavior. Do not squeeze a desktop calendar into a phone-sized popup. |
| F18 | PIN/OTP field — 1.x | Length, paste/autofill, obscured, invalid/busy | Prefer one logical editing control with segmented visuals; do not break password-manager, paste, or screen-reader behavior into unrelated fields. |
| F19 | File input — Adapter | Single/multiple, file types/limits, clear/preview | Optional file-picker/drop adapter; core value model can use bytes/streams/metadata rather than platform paths. Application owns permission and upload. |
| F20 | Color picker — 1.x | Swatches, text color input, optional alpha | Typed Color field; keyboard-operable channels and validation. Visual selection does not guarantee foreground contrast. |
| F21 | Rating input — 1.x | Read-only/interactive, range/precision, labels | Semantic value and keyboard increment/decrement; stars are decorative representations, not unlabeled buttons. |

### Shared form state contract

- Support controlled value+callback and an explicitly documented uncontrolled
  initial-value mode; do not require both value and controller simultaneously.
- Integrate with Flutter Form's validate/save/reset; external error state is
  distinct from local validator output with explicit precedence.
- Support disabled, read-only, required, focused, dirty, touched, invalid, and
  validating states where relevant. Define state combinations.
- Default validation timing should be understandable (submit or user interaction);
  provide on-blur/async policies deliberately, without flashing errors on load.
- A form coordinator can scroll/focus the first invalid field and show a summary.
  It must work with lazy/hidden fields and avoid trapping the keyboard.
- Preserve text selection, composing ranges, and values when theme/root/width
  changes. Reset only when requested by the application.
- Labels, helper/error text and counters grow with text scale; error indication
  combines text and other cues, not only a red border.
- Applications provide localized strings, formatters, backend validators, and
  submitted models. Do not add an application-specific schema engine to core.

### Slider/range implementation details

Normalize values within a finite `min < max` domain. Specify whether out-of-range
caller values are rejected or normalized (recommended: reject invalid config,
document precision tolerance). Validate positive step and reachable endpoints.
Use controlled values; notify during drag and separately on commit. Keyboard
steps use the same domain policy; semantics announce formatted current/range
values. RTL changes the visual direction according to a documented policy;
tests verify that labels and increment/decrement intent remain understandable.

Vertical sliders, logarithmic domains, multiple handles, and custom discrete
marks are 1.x extensions. Do not reimplement noUiSlider in Flutter as part of MVP.

Unique proof: controller disposal and swaps; form reset/save; locale decimal
input; IME composition; async-result ordering; password reveal caret retention;
date-only values across timezone boundaries; slider keyboard endpoints and
range handles; label/error layouts at large text sizes and RTL.

## 7. Progress, loading, status, and feedback

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| B01 | Alert/banner — MVP | Success/info/warning/danger, title/body/action, dismissible | Shared semantic status styles; icon+text and named close action. Decide when announcements are appropriate, not every rebuild. |
| B02 | Toast/snackbar — 1.0 | Severity, action, queue, dismiss, timeout/persistent | ScaffoldMessenger or a tested host/service interface. Pause/extend duration appropriately for interaction/accessibility; avoid interrupting focus. |
| B03 | Linear progress — MVP | Determinate/indeterminate, intent, thickness, label | Wrap LinearProgressIndicator and explicit semantics/value model. Default percentage label outside track. |
| B04 | Circular progress — MVP | Determinate/indeterminate, size/stroke, label | Native CircularProgressIndicator with tokens; no duplicate status announcement inside button + indicator. |
| B05 | Spinner / busy indicator — MVP | Inline/block, accessible busy description | Share B04 indeterminate behavior, not a second incompatible progress model. Respect reduced motion and expose meaningful static busy text. |
| B06 | Skeleton — MVP | Text/image/avatar/rect, grouped placeholders, animation opt-in | Reserved geometry and ExcludeSemantics for decorative shapes. Reduced-motion fallback and no shimmer as an uncontrolled always-on default. |
| B07 | Empty/error/offline state — MVP | Illustration/icon, heading, description, retry/primary action | Composable state panel with caller callbacks and actual error policy. Offline status supplied by app, not guessed from a single failed request. |
| B08 | Upload/task progress list — 1.0 | Per-item queued/running/succeeded/failed/cancelled; bytes or percentage; cancel/retry | Pure presentation over typed task state. File transfer/network transport in optional adapter or app. Aggregate progress only when totals are known. |
| B09 | Status/legend indicator — 1.0 | Dot+text, intent, online/away/custom domain meaning | Share badge/semantic colors; caller supplies localized status, no polling service. |

### Progress value model

Use either a bounded normalized progress value or `(completed, total)` with
explicit validity rules. `null` means indeterminate, not zero. Unknown totals
must not show a invented percentage. Distinguish active, paused, completed,
failed, and cancelled task states from the numeric fraction.

Expose label and formatted value in semantics. Avoid announcing every animation
frame or byte update; define a throttled meaningful-update policy. Labels should
remain readable at 0%, small percentages, and 100%; external labels avoid
contrast/clipping problems inside narrow tracks. Stacked progress segments are
1.x after the basic single-task model is stable.

Indeterminate motion respects `MediaQuery.disableAnimations`/accessibility
policy. Never stop conveying that a task is busy merely because animation is
disabled. Dispose ticker/subscriptions and stop background animations when
hidden. Skeletons never claim that real content or controls are loaded.

Unique proof: 0/1/unknown/invalid progress; completion vs cancellation; no spam
announcements; contrast of text/track; queued toast dismissal/action races;
background ticker cleanup; retry only invokes the provided callback.

## 8. Overlays and contextual actions

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| O01 | Dialog/modal — 1.0 | Sizes, title/body/actions, scrolling, fullscreen phone adaptation | Build on DialogRoute/showDialog; local theme/metrics, focus containment, labelled route, Escape/back and dismiss policy. |
| O02 | Confirmation dialog — 1.0 | Confirm/cancel, destructive intent, busy/error | O01 composition; caller performs operation. Appropriate initial focus and explicit dismissal while busy. |
| O03 | Drawer/offcanvas/bottom sheet — 1.0 | Directional start/end/bottom, modal/persistent, swipe where supported | Native drawer/bottom-sheet primitives; safe area and keyboard inset handling. Restore focus and support application back navigation. |
| O04 | Popover — 1.0 | Anchored placement, collision avoidance, interactive content | OverlayPortal/anchored follower or suitable native API. Responsive fallback to sheet/dialog when content cannot fit. |
| O05 | Tooltip — MVP | Text/rich content only if safe, hover/focus/long press, delay | Prefer native Tooltip; keyboard discoverability and explicit semantic duplication policy. Essential instructions are not tooltip-only. |
| O06 | Dropdown/menu — 1.0 | Action groups, separators, checked items, submenus later | Shared menu model and native MenuAnchor where appropriate. Arrow/Home/End/Enter/Escape behavior and focus restoration. |
| O07 | Context menu — 1.0 | Secondary click, keyboard invocation, mobile alternative | O06 placement adapter; always provide a discoverable non-right-click alternative. |

Build a common overlay contract for dismissal reason, focus ownership/restoration,
theme/metrics propagation, anchor lifetime, safe bounds, barrier behavior, and
stacked overlay ordering. A closed overlay cannot leave a transparent focusable
layer behind. Route dismissal returns typed result data, not application effects.

Unique proof: nested menus/dialogs; destroyed anchor; navigation while open;
theme switching in popup; keyboard trapping/restoration; screen-reader title;
phone keyboard overlap; barrier/Escape/back semantics; interactive popover must
not behave like a passive tooltip.

## 9. Navigation

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| N01 | Tabs — 1.0 | Underline/contained, scrollable, icon+label, lazy/stateful panels | Shared tab model; native TabBar/TabController where suitable. Document automatic vs explicit activation and state-retention policy. |
| N02 | Navbar/app header — 1.0 | Brand/title, actions, compact menu trigger, sticky recipe | Responsive composition; do not hide destinations without an accessible overflow pattern. |
| N03 | Sidebar — 1.0 | Expanded/icon-only, groups, nested items, active/disabled | Shared navigation item IDs, current-page semantics, labelled collapsed icons, state preserved across responsive transitions. |
| N04 | Breadcrumb — 1.0 | Separator, current item, mobile truncation/overflow | Typed breadcrumb list; application routing callbacks. Collapsed ancestors remain accessible through menu. |
| N05 | Pagination — 1.0 | Pages/ellipsis, next/previous, unknown-total option, page size | Controlled index and counts; visible page changes, named controls. Does not fetch or sort data itself. |
| N06 | Stepper — 1.0 | Horizontal/vertical, current/completed/error/disabled, optional steps | Controlled workflow model; validation/navigation owned by caller. Focus and announcements for step changes. |
| N07 | Bottom navigation — 1.0 | Icon+label, badges, selected destination | Native NavigationBar facade with tokens and typed shared destinations. Avoid too many primary destinations; overflow is a deliberate pattern. |
| N08 | Navigation rail — 1.0 | Compact/extended, leading/trailing actions | Same destinations as sidebar/bottom navigation so state survives width transitions. |
| N09 | Scrollspy/section navigation — 1.x | Active section, anchor scrolling, reduced-motion behavior | Scroll-position adapter; account for sticky header offsets and async section size changes. |
| N10 | Mega menu — 1.x recipe | Grouped links, columns, responsive collapse | Compose tested menu/navigation primitives; do not make hover the only opening mechanism. |

Navigation is router-neutral. Publish recipes for the supported Flutter routing
approach and an optional common router adapter, without adding routing to core.
Destination IDs stay stable across layouts; current destination and history are
owned by the application. Decorative active styles do not replace selected/current
semantics. Deep links and mobile back behavior belong in recipe integration tests.

## 10. Cards, lists, disclosure, and data display

| ID | Component / target | Required variants and states | How to add it |
| --- | --- | --- | --- |
| D01 | Card — MVP, extend existing | Plain/outlined/elevated; header/body/footer/media; explicit interactive wrapper | Token surface and slots; optional surface theme. Clickable card has separate semantic/focus behavior and avoids nested competing actions. |
| D02 | List/list tile — MVP | Leading/trailing, title/subtitle, selection, dense visual option, lazy collection | Native ListTile/list rendering where useful; variable height and typed selection. Interactive vs presentation item explicit. |
| D03 | Accordion/collapse — 1.0 | Single/multiple open, disabled panels, retain/dispose content | Expansion primitives plus controlled open IDs. Header is keyboard button with expanded semantics; hidden content leaves focus/semantics. |
| D04 | Table — 1.0 | Columns, sort intent, selection, row actions, empty/loading/error, responsive overflow | Start with bounded data sets and native table semantics where available. App owns sorting/filtering/paging; announce sort direction and selection. |
| D05 | Responsive data list — 1.0 | Table→cards or explicit horizontal scroll; key-value labels | Alternate presentation supplied by schema/item builder. Essential columns are not simply removed on phones; stable row identity and actions. |
| D06 | Stat/metric — 1.0 | Value, label, trend, comparison period, loading | Compose text/card/badge; formats supplied by caller. Trend meaning includes text/icon and explicit good/bad policy. |
| D07 | Timeline — 1.0 | Vertical, grouped events, status, time labels, optional actions | Directional list composition with accessible event order; formatting/timezone belongs to app. Decorative line excluded from semantics. |
| D08 | Tree view — 1.x | Expand/select, keyboard levels, lazy nodes | Separate tree controller/model and roving focus; stable IDs and async expansion. Do not fake a tree as unlabeled nested lists. |
| D09 | Virtualized/pinned-column data grid — 1.x | Huge data, pinned rows/columns, resize/reorder | Profile before custom rendering; optional specialized integration may be better than a new engine. Dedicated keyboard/accessibility work required. |

For tables define empty vs loading vs filtering-to-zero; row identity; selection
across pages; sortable nullable values; data ownership; layout width and horizontal
scroll; accessible headers; large text; and localized number/date formatting.
Do not advertise spreadsheet editing, virtualization, or server sorting before
those behaviors actually exist. Publish explicit size/performance limitations.

## 11. Optional integrations and application patterns

| ID | Extension / target | Planned boundary |
| --- | --- | --- |
| X01 | Charts — Adapter | Theme colors/type/grid helpers and accessible summaries around a maintained chart library; no core chart renderer. |
| X02 | Maps/datamaps — Adapter | Provider-owned credentials/tiles, optional plugin, sizing/controls themes; no default paid provider or hidden network calls. |
| X03 | Rich editor — Adapter / 1.x | Evaluate editor packages for selection, IME, document format, licensing and web support; text input remains independent. |
| X04 | File picking/dropzone/upload transport — Adapter | Browser/native capability differences, optional pick/drop plugins, app-supplied uploader with cancel/retry; B08 renders state. |
| X05 | Command palette — 1.x | Searchable typed actions, keyboard shortcut, overlay and focus foundation; registered application actions, not framework magic. |
| X06 | Full calendar/scheduler — 1.x | Events, timezone/DST, drag and recurrence need an independent product scope; date field is not a scheduler. |
| X07 | Chat/message bubbles — 1.x recipe | Compose avatar, text, card, timestamps, attachments; conversation storage/streaming not in UI core. |
| X08 | Drag-and-drop — Adapter / 1.x | Reorderable UI plus keyboard alternative; distinguish internal reorder from cross-app file dropping. |
| X09 | Motion/confetti — Adapter | Optional, reduced-motion-aware; no celebration effects in default form components. |
| X10 | Token import / CLI / theme persistence — 1.x or Adapter | Versioned schema and migrations; designer imports validated; persistence/state-library adapters remain optional. |

## 12. Recipes required for 1.0

Publish complete, executable examples for: login/password reset; registration
with validation; profile/settings with avatar/image handling; responsive dashboard;
filter/search results with pagination; upload-state presentation with a fake
uploader; list/detail with preserved state; accessible confirmation workflow;
marketing hero/features/pricing; data table with mobile alternative; and a themed
RTL/large-text page. Examples use fictional local data by default and clearly
label optional integrations. They are not live backend products.

## 13. Choosing between reuse and custom implementation

Use Flutter primitives first for buttons, text editing, sliders, checkbox/radio,
switch, scrolling, tabs, progress, image providers, tooltips and basic dialogs.
Compose custom framework behavior for tokens, responsive values, layout,
surface/field shells, semantic status styles, navigation models and recipes.

Prototype custom controls only when existing primitives cannot satisfy a
documented requirement. Before adding a dependency, assess platform support,
maintenance, license, accessibility, size, performance, controller lifecycle,
and transitive dependencies. Evaluate licenses before copying any external code
or assets; this plan uses external libraries as research, not as imported code.
