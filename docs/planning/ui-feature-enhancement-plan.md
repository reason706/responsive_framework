# UI Improvement and Feature Enhancement Plan — Built-in Design Quality

**Status:** proposed; this document does not implement the changes below.
**Baseline:** GitHub `main`, commit `04d75f0`.
**Date:** 12 October 2026 (Australia/Sydney).
**Focus:** better built-in utilities, tokens, visual defaults, components and UI
features during the framework's first product-building stage.

## 1. What this improvement track is for

Improve the interface that the framework produces out of the box. A developer
should be able to compose its existing widgets and obtain intentional spacing,
readable type, clear actions, coherent surfaces and complete interaction states.
The default component set should feel designed together, rather than assembled
from many unrelated demonstrations.

This track prioritizes the actual UI and useful features. It does not introduce
a golden-test program, release/publishing infrastructure, consumer theme builders,
headless customization APIs, `StyleDelta` escape hatches, a CLI, or an application
backend. Existing functional checks remain useful supporting verification, but
they are not the deliverable or the main improvement effort.

Existing themes and presets remain supported. Improving their built-in behavior
is in scope; expanding the machinery for users to invent their own design
systems is deferred. Internal shared metric recipes are allowed because they
make defaults consistent; they need not become public customization APIs.

The complete original plan remains the framework specification. This document
defines the **next UI-focused improvement track**, after the substantial
implementation and Improvement Plan 2 work already merged.

## 2. Assessment: does the current UI meet the intended design standard?

### Evidence reviewed

- The current release gallery was rendered in Chromium at 1440×1100.
- The initial controls/card grid and the foundation/preset area were inspected.
- Source was reviewed for typography, spacing, icons, surfaces, layout utilities,
  field decoration, card composition and theme propagation.
- The preceding baseline check passed 794 repository tests, formatting, analysis
  and the gallery web build. That establishes useful functional evidence, not
  that every component is visually polished.

The browser review covers representative screens, not every component or every
state. Findings below are labelled as observed, source-confirmed or proposed.

### Verdict

**Partially aligned with established UI principles; a strong implementation
foundation with uneven visual polish.** Material-based controls, root-relative
lengths, semantic colors and directional layouts are good foundations. The
sampled gallery demonstrates those capabilities but still reads as an engineering
catalog. It does not yet establish a consistently senior-designed product UI.

"Senior-designed" is a qualitative judgment about hierarchy, restraint, visual
relationships, interaction clarity and attention to edge cases. There is no
universal certification for it, and the use of Material widgets alone does not
prove it. This plan makes that judgment actionable through review criteria.

### Findings and limits

| Area | Current evidence | Improvement needed |
| --- | --- | --- |
| Color and surfaces | Observed: a consistent purple family, but broad tinting and repeated raised cards dominate the sample | Establish clearer page/surface/raised relationships; reserve emphasis for meaningful actions |
| Dark previews | Observed: several dark preset captions were difficult to read; the inverse preview also needs foreground review | Resolve text/icon colors against the actual local surface, including native Text and button tables |
| Preset identity | Observed: the Monochrome preview uses a visibly chromatic cyan primary treatment | Make the built-in Monochrome brand treatment achromatic; do not assume a gray seed guarantees a gray generated palette |
| Typography hierarchy | Observed: component labels and body copy have limited distinction; controls occupy much of the first viewport | Define page/section/component/metadata hierarchy and apply it consistently |
| Root-relative utilities | Source-confirmed: `paddingToken` calls legacy `FwSpacing.of`, while newer layout primitives use `spaceScale` | One root-aware resolution contract for equivalent token utilities |
| Density | Source-confirmed: `FwBox` scales every padding through density, while other insets can remain raw-root-based | Separate content/layout spacing from compact control spacing deliberately |
| Radius ownership | Source-confirmed: `FwCard` uses generic `radii.lg` although component-class radius tokens exist | Use one canonical built-in recipe per component family |
| Icon gaps | Source-confirmed: aliases include 2px `iconGap` and 6px `hairlineGap`; normal button documentation specifies 8px | Give each gap a precise purpose and avoid using a micro gap as a general icon-label gap |
| Font completeness | Source-confirmed: typography names RobotoMono; the gallery bundles Roboto Regular/Medium/Bold | Ensure demonstrated monospace and required weights have real licensed font assets or explicit fallbacks |
| Gallery structure | Source-confirmed: many boards are placed in one long page with raw layout spacers | Provide focused browsing and purpose-specific examples using the framework itself |
| Whole-catalog polish | Not fully reviewed in this pass | Audit every family and state with the checklist below; do not mark all components polished from two screenshots |

### Standards versus design decisions

Use Material 3 for control behavior, state feedback, typography roles and
surface/elevation relationships; Bootstrap/Preline for composition and component
patterns; WCAG-relevant guidance for contrast, visible focus and understandable
interaction. These systems are references, not one interchangeable visual spec.

Choose a coherent Material-informed, restrained application style for the built-in
defaults. A standard can have several valid appearances. Purple surface tint,
rounded cards or a 14px label are not automatically violations; poor contrast,
ambiguous actions and inconsistent relationships need concrete correction.

Proposed sizes and gaps below are **framework design choices at root 16**, not
a claim that Material or Bootstrap mandates every listed number.

## 3. Default visual direction

1. A quiet page canvas, clearly distinguishable content surfaces, and limited
   primary-color emphasis.
2. A visible hierarchy from page heading to section heading, component label,
   body copy and metadata; avoid making everything the same size and weight.
3. Small related gaps, larger group gaps and clearly larger section gaps.
4. Consistent corner families, fine borders and shallow resting elevation.
5. One strong primary action in an action group; secondary actions remain clear.
6. Icons with consistent sizes, stroke families and optical alignment.
7. Complete hover/focus/pressed/selected/disabled/loading/error presentation.
8. Responsive composition through wrapping, stacking and reflow; readable text
   sizes remain meaningful rather than shrinking the whole interface.
9. Full-size content examples as well as compact component demonstrations.
10. Useful motion that communicates state, with a reduced-motion alternative.

The objective is a coherent default identity. Avoid adding gradients, glass,
heavy shadows, excessive pills or animation simply to make the catalog look new.

## 4. Token improvements — design the built-in defaults first

### 4.1 Spacing and size tokens

Retain the existing root-relative scale and its numeric parity at root 16.
There is already a useful range through s40; another large scale expansion is
not the next priority. Improve semantic meaning and component adoption.

| Task | Built-in improvement | Initial target | Acceptance |
| --- | --- | --- | --- |
| T-01 | Canonical spacing resolver | Root-relative values for every equivalent named-token utility; fixed px remains explicit | Token padding agrees between helpers at roots 16/18/20 |
| T-02 | Precise semantic gaps | Separate label→control, control→helper, field→field, icon→label, group and section spacing | Components use the alias matching the relationship, not one fieldGap everywhere |
| T-03 | Control size recipes | Internal metric tables for xs/sm/md/lg where supported | Same-size buttons/fields/selects align when placed in one row |
| T-04 | Density ownership | Density compacts control internals and deliberate dense collections; page/media spacing has a separate policy | Compact controls retain readable type and supported touch targets |
| T-05 | Border/focus metrics | Distinguish resting hairline, active border and focus-ring width/offset | Focusing a field does not jump its geometry or hide its error state |
| T-06 | Component radius use | Canonical button/input/card/menu/dialog/chip recipes consume their assigned tokens | No family picks an unrelated generic radius by accident |
| T-07 | Icon metrics | Small/normal/large glyph grid and role-specific gaps | Button, field, menu and navigation icons share alignment rules |
| T-08 | Image/avatar metrics | Shared aspect-ratio, diameter and frame spacing presets | Placeholders/errors/fallbacks retain expected geometry |

Suggested semantic relationships, before density and system text scaling:

| Relationship | Proposed baseline |
| --- | --- |
| Button icon→label | 0.5rem (8px) |
| Compact metadata icon→text | 0.25rem (4px) |
| Fine decorative separation | Explicit 2px micro token only where justified |
| Field label→control | 0.375rem (6px) |
| Control→helper/error | 0.25–0.375rem (4–6px) |
| Field→field | 1rem (16px) |
| Related settings group | 1.5rem (24px) |
| Card content inset | 1–1.5rem depending on the built-in size recipe |
| Section separation | 2–3rem; fluid larger spacing for marketing sections |
| Page inline inset | 1rem narrow, 1.5rem medium, 2rem wide |

Review these with real screens before freezing them. Keep 4px rhythm where
appropriate, allow intentional 2px optical adjustments, and avoid pretending
that every spacing value must be an 8px multiple.

### 4.2 Typography and font tokens

| Task | Improvement | Acceptance |
| --- | --- | --- |
| T-09 | Clear role hierarchy | Page title, section title, card title, field label, body, help and metadata are visually distinguishable |
| T-10 | Actual font faces | Demonstrated semibold/monospace faces exist or use a documented installed equivalent; no accidental proportional code font |
| T-11 | Reading measure | Long-form body content has a comfortable max measure; dashboard grids can remain wide |
| T-12 | Contextual label sizes | Normal labels remain readable; 11px uppercase overline is supplementary, never critical form instruction |
| T-13 | Numeric presentation | Metrics/tables use tabular figures and intentional alignment; currency/unit labels have hierarchy |
| T-14 | Responsive type adoption | Framework/native text inside built-in components agrees with root metrics; fluid headings remain bounded |

Suggested hierarchy at root 16: page heading 28–40px fluid, section heading
20–24px, card heading 18–20px, body 16px, UI label 14–16px, helper/metadata
12–14px. These are starting recipes, not a second competing typography scale.
Map them to existing roles. Keep line-height and paragraph spacing intentional.

TextScaler continues to apply once. Spacing is not multiplied by the OS text
scale; controls accommodate enlarged text through content-driven height and
wrapping. The default root remains 16, with existing explicit root controls.

### 4.3 Color, state and surface tokens

| Task | Improvement | Acceptance |
| --- | --- | --- |
| T-15 | Surface hierarchy | Page, content, inset and raised surfaces are distinguishable in light/dark |
| T-16 | Foreground pairing | Text/icon/helper roles resolve against their actual surface, including local inverse regions |
| T-17 | Consistent emphasis | Primary actions carry the strongest emphasis; selected/status treatments do not all compete with them |
| T-18 | State layers | Hover/pressed/focused/selected/error/disabled combinations use shared rules and remain distinguishable |
| T-19 | Status readability | Success/info/warning/danger use text/icon cues and readable foregrounds, not just hue |
| T-20 | Resting elevation | Flat/inset content is not raised by default everywhere; raised depth communicates an actual relationship |
| T-21 | Preset identity | Named built-in presets match their visual intent; Monochrome uses a validated achromatic brand treatment with documented status-color exceptions |

Make local themes update all relevant built-in token tables. The review already
reproduced a dark scope retaining its parent's button colors; fixing this is
part of making the built-in UI coherent, not a new customization product.

Do not use one opacity value to produce all disabled text without checking the
resulting surface. Focus outlines must be visible against both the control and
its surroundings. Error and focus states can coexist.

## 5. Utility improvements and additions

Improve the existing primitives before creating near-duplicate wrappers.
All names below are proposed unless an existing implementation is identified.

| ID | Utility work | How to implement it | User-visible result |
| --- | --- | --- | --- |
| U-01 | Repair `paddingToken` resolution | Resolve with the current root-aware spaceScale, preserving legacy custom pixel behavior through an explicit migration | Helpers and built-in layouts scale consistently |
| U-02 | Directional spacing helper completeness | Start/end, inline/block and responsive inset convenience using the same resolver | Clear RTL-safe composition without hand-coded EdgeInsets |
| U-03 | One box/padding convention | Keep layout FwBox as the canonical padding primitive; clearly distinguish the existing decorative box | No confusing two different FwBox meanings in examples |
| U-04 | Semantic section/field stacks | Build on FwVStack/FwHStack and semantic group gaps | Consistent form/page grouping with less arbitrary spacing |
| U-05 | Consistent wrap/inline behavior | Align gap/runGap/rowGap resolution and precedence across existing helpers | Chips, actions and metadata wrap with the same rhythm |
| U-06 | Reading-width helper | A focused content-width recipe using existing FwLimits/containers; add a named helper only if it removes repeated logic | Body copy does not stretch across an entire desktop |
| U-07 | Action-row helper | Wrap-to-stack actions with end alignment, consistent gap and deliberate mobile order | Dialog/card/form actions look related across widths |
| U-08 | Icon-label composition | Share gap, alignment and size behavior; glyph mirroring opt-in according to meaning | Cleaner action, navigation, field and metadata alignment |
| U-09 | Media frame composition | Aspect reservation, clipping, placeholder and caption spacing using existing image/figure primitives | Images and errors retain a designed frame |
| U-10 | Surface treatment helper | A small built-in set: plain, outlined, inset and raised, using existing surface tokens | Consistent panels without ad hoc shadows and radii |
| U-11 | Truncation/line-clamp utility | Explicit optional truncation with a full-content access pattern | Cleaner lists without hiding essential labels/instructions |
| U-12 | Loading-content composition | Shared busy label, progress and pointer/focus policy; retain dimensions | Loading states look intentional and cannot activate hidden controls |

Surface/media/action helpers should first be internal/shared recipes or small
compositions. Promote a public widget only when the behavior is reusable and
the name is clear. This is not a CSS string parser or a generic style builder.

### Utility rules

- Container gaps own sibling spacing; outer spacing is explicit and does not
  claim CSS margin collapse.
- Fixed-pixel exceptions are named and purposeful: hairlines, glyph grids and
  optical adjustments. Content insets usually follow root units.
- Compact density must not shrink reading-width or image-frame geometry blindly.
- No implicit Expanded under arbitrary parents; no hidden unconstrained axes.
- Wrapper order is documented: outer padding and decoration padding differ.
- Equivalent helpers produce equivalent geometry; avoid separate resolution
  logic in components, layout and utilities.

## 6. Component-by-component improvement slate

Every shipped family is eligible for review. Existing behavior should remain
unless a specific usability, consistency or visual problem is identified.
Families marked below for review are not all claimed to be defective.

| ID | Family | Visual/UX improvements | Built-in feature enhancements |
| --- | --- | --- | --- |
| C-01 | Buttons and icon actions | Unify baseline, sizes, icon gaps, shape and emphasis; stronger selected/focus/loading distinction | Stable busy width, icon-leading/trailing consistency, coherent grouped/split actions |
| C-02 | Toggle/segmented groups and FABs | Equal segment heights, balanced spacing, clear selected state, restrained FAB depth | Consistent wrapped/vertical groups and readable speed-dial action labels |
| C-03 | Text, links, read-more, code/kbd | Apply hierarchy, reading measure, actual monospace, obvious links and useful metadata contrast | Reliable clamping/read-more, consistent inline icon links and copy feedback |
| C-04 | Text/password/search/textarea fields | Persistent labels, aligned prefix/suffix, consistent border/radius, quiet helper text and readable errors | Clear/pending/success states with stable layout; textarea counter and auto-growth policy |
| C-05 | Checkbox/radio/switch/select | Align hit regions and multiline labels; clarify selected/disabled/error combinations | Whole-row selection where appropriate, grouped descriptions and selectable option cards |
| C-06 | Number/date/time/phone/OTP/tag fields | Align these with ordinary inputs; unify formatting/error/help presentation | Consistent empty/reset/validation states and form-controller participation; preserve caret/composition |
| C-07 | Linear/range/vertical/circular sliders | Balance track/thumb/value emphasis, marks and labels; avoid values colliding at endpoints | Coherent formatted value display, optional reset-to-default, range summary and units |
| C-08 | Cards, panels, list tiles, description lists | One surface vocabulary, consistent slot gaps and radius; aligned metadata/actions | Shared header/action/media/footer compositions and useful compact list descriptions |
| C-09 | Images, figures, avatars/groups, photo viewer/carousel | Aspect reservation, meaningful crops, readable captions, stable fallbacks and proportionate avatar status | Bounded fallback frames, thumbnail selection and optional visible media actions |
| C-10 | Progress/gauges/upload task lists | Keep percentages readable, clarify progress versus status, standardize thickness/color/label placement | Shared task-state summary, cancel/retry presentation and completion/error transitions |
| C-11 | Skeletons, shimmer, empty/error/offline states | Content-shaped skeletons, quiet motion, balanced illustration/title/body/action | Static reduced-motion alternative, designed retry/empty guidance; safe inactive loading subtree |
| C-12 | Alerts, banners, toast and notification center | Clear title/body/action hierarchy, readable severity cues and consistent dismiss actions | Readable long messages, visible undo/retry, sensible grouping and unread summaries |
| C-13 | Dialog, drawer, sheet, side sheet | Consistent title/body/footer, padded safe edges and purposeful size/elevation | Narrow-screen action stacking, visible scroll boundaries and busy dismissal guidance |
| C-14 | Menus, popovers, tooltip, hover card, command palette | Aligned item rows, shortcut columns, clear active/disabled state, restrained shadow | Search/no-results/status presentation; pointer and keyboard affordances agree |
| C-15 | Navbar/sidebar/rail/bottom navigation | Clear active destination, consistent icon-label metrics, readable collapsed items | Useful group headings, badge alignment and persistent destination identity on adaptation |
| C-16 | Tabs, breadcrumbs, pagination, steppers | Balanced spacing, obvious current/selected state, readable overflow choices | Results/page summaries, clear optional/error steps and controlled mobile reflow |
| C-17 | Table/responsive data cards/tree | Strong header/row hierarchy, aligned numeric columns, clear selected/sort states | Search/filter/selection action presentation, mobile data summaries and useful empty states |
| C-18 | Stat, timeline, calendar, rating | Tabular figures, measured emphasis, quiet supporting trends/time labels | Comparison captions, range summaries, non-color status cues and clear interactive/read-only states |
| C-19 | Onboarding, tour, chat, swipe/refresh | Consistent chrome and action language; affordances visible before gestures | Discoverable gesture alternatives, page/step status and predictable end-of-list feedback |
| C-20 | Signature, color picker, QR, dotted borders, resizable panels | Shared control chrome, clear tool actions and bounded decorative effects | Reset/clear/download hooks where useful; readable selected color/position/state summaries |
| C-21 | Adaptive counterparts | Same content hierarchy, semantic meaning and root/density policy within platform-appropriate visuals | Align the existing six variants first; add text-field/picker parity only after shared defaults are settled |

### Action and field metric starting point

At root 16, begin with a normal 16px body/input value, 14–16px UI label,
20px action icon, 8px icon-label gap, 16px inline padding and content-driven
block padding. Keep the supported touch target at least 48 logical pixels.
Small visuals may sit within that target; fixed visual heights must not clip
large or wrapped labels.

Use a 1px resting border and a clear focus treatment. Reserve filled/solid
primary emphasis for the main action. Outline/ghost treatments must remain
recognizable as actions in their context. Destructive intent gets explicit
language and appropriate presentation, not a red theme applied everywhere.

### Field-state completion

Present initial, focused, populated, validating, invalid, read-only, disabled
and success states as one coherent family. Preserve label and value positions
when indicators appear. Pending feedback should not incorrectly display success.
Errors should identify the problem and a recovery action where possible.

The previous review reproduced stale async validation and notification after
disposal. Correct those while implementing reliable pending/error UI. Wire the
remaining wrapper fields into the controller so visual validation conventions
are consistent. This work supports user-visible form quality; it is not a new
general schema/form-builder product.

### Overlay and data refinements

Overlay headers, content and action areas should have the same spacing grammar.
Primary/secondary actions need intentional ordering and stacking on phones.
Status messages cannot be clipped beneath a keyboard or an overlay boundary.

Tables use subdued headers, clear selected rows, right-aligned numbers where
appropriate, and useful empty/filter states. Mobile layouts preserve essential
data and actions. Add better default row and filter presentation before starting
a spreadsheet engine or a large virtualization project.

## 7. Feature additions — useful building blocks, not more arbitrary knobs

The following named types were not found in the reviewed public implementation.
Names remain provisional. Several features should begin as recipes around the
existing components; a new public class is not mandatory for every row.

| ID | Addition | What it contributes | Implementation boundary |
| --- | --- | --- | --- |
| F-01 | Page header / section header | Title, description, breadcrumb or metadata, primary action and responsive wrapping | Compose current text/breadcrumb/action primitives with fixed built-in spacing recipes |
| F-02 | Form section / field group | Clear title/help, consistent field grid and group separators | Compose existing fields and stacks; keep validation ownership unchanged |
| F-03 | Toolbar / action bar | Consistent grouped actions, search, selection summary and mobile overflow | Build on action/menu helpers; no application command registry |
| F-04 | Input-group recipe | Attached prefix/unit/suffix action with coherent border and alignment | Extend existing prefix/suffix handling; avoid a duplicate editor or conflicting controller |
| F-05 | Selection card / setting row | Clear whole-option hit area, title/description/icon and selected feedback | Compose existing checkbox/radio/switch with one controlled selection model |
| F-06 | Filter bar / result summary | Search, active filter chips, clear action and result count | Presentation and callbacks over app-supplied state; no remote querying engine |
| F-07 | Media-card recipe | Image + caption/metadata/actions with reserved geometry | Improve current card/media/figure composition before adding a wrapper class |
| F-08 | Upload-panel presentation | Drop/browse visual, type/size guidance, selected-file and task-state summaries | Caller supplies selection/drop/upload events; platform picking and transport remain outside this track |
| F-09 | Step-progress / task-summary recipe | Coherent multi-step process, current step and pending/completed/error guidance | Compose existing stepper/progress/task models; avoid misleading estimated completion |
| F-10 | Metric-row / metric-grid recipe | Aligned value/label/trend/comparison displays | Use existing stats/grid and numeric typography; formatting stays explicit |
| F-11 | Inline helper / callout recipe | Small contextual explanation, warning or recovery message beside a control | Reuse alert/banner/text roles, with restrained appearance; no duplicate severity system |
| F-12 | Focused component gallery browser | Search/category navigation, concise overview and one focused live preview per family | Improve the gallery application, not a new framework runtime dependency |

Initial selection: F-01, F-02, F-03, F-05, F-06 and F-12 have the clearest
composition value. Implement the others after their underlying components receive
the polish pass. Avoid presenting existing carousel, calendar, hover-card or
command-palette features as missing; they are already implemented.

## 8. Gallery: demonstrate design quality, not only API coverage

The long catalog is useful as an inventory, but it is not the best demonstration
of how the framework produces a composed UI. Add:

- A compact landing overview with the framework identity, key capabilities and
  links to foundations, components and complete examples.
- Category navigation/search so users do not scroll through every board.
- A focused component page: purpose, anatomy, state examples, responsive preview
  and a short correct snippet. Keep detailed boards accessible without making
  them all the initial view.
- A compact preview control area; the initial settings panel should not dominate
  the whole first viewport at desktop width.
- Readable light/dark comparison previews that resolve their own text and icon
  colors; repair the dark preset caption issue seen in this review.
- Three carefully composed examples: profile/settings, dashboard/results and a
  marketing/content page. Existing pilot apps supply the starting compositions.

Each example should use a consistent page header, reading hierarchy, group
spacing, one dominant action and realistic content. Avoid invented charts or
simulated service success presented as working integrations.

The visual goal is restrained confidence: enough negative space, clear emphasis,
good alignment and complete states. More cards, shadows or moving skeletons do
not automatically improve the design.

## 9. Implementation order

| Wave | Scope | Concrete exit condition |
| --- | --- | --- |
| W1 — default consistency | T-01/T-02/T-05/T-06/T-16, U-01/U-03/U-12; local palette and loading fixes | Equivalent spacing agrees, dark previews are readable, inactive loading content cannot activate |
| W2 — type, color, shape | T-03/T-04/T-07/T-09–T-21; foundational component recipes | One coherent action/input/surface/type board across light/dark and narrow/wide |
| W3 — utilities and composition | U-02/U-04–U-11; F-01/F-02/F-03/F-05 | Header + form + action area compose without ad hoc gaps or mismatched metrics |
| W4 — family polish | C-01 through C-21, prioritized actions→fields→surfaces→feedback→navigation/data | Every family has reviewed defaults and relevant state/size examples |
| W5 — purposeful features | F-04/F-06–F-11, selected after underlying improvements | Useful real compositions demonstrate the added features without duplicate logic |
| W6 — showcase refinement | F-12 and three composed examples | The gallery communicates visual identity and quality without requiring an endless scroll |

W4 is several small batches, not one giant change to every component. For a solo
developer, use initial planning ranges of 1–2 weeks for W1, 1–2 for W2, 1–2 for
W3, 3–5 for W4, 2–3 for W5 and 1–2 for W6. Refine after the first visual batch;
estimated effort depends on how many new public widgets are actually justified.

Work that only updates the plan or README does not complete a wave. Every future
implementation batch should record which default behavior changed and why.

## 10. Practical design review checklist

Use this checklist for every relevant family and composed example. Mark each
item reviewed/needs work/not applicable; avoid an invented numeric design score.

| Dimension | Question that must be answered |
| --- | --- |
| Hierarchy | Can the primary title/action be found quickly? Are labels/body/metadata distinct? |
| Rhythm | Are related items closer than separate groups? Do gaps follow intentional tokens? |
| Alignment | Do glyphs, labels, values and action edges align optically as well as geometrically? |
| Proportion | Are icon/label, control/content and title/body sizes balanced? |
| Surfaces | Does depth indicate grouping and elevation rather than decorate every region? |
| Color | Does the local foreground remain readable? Does semantic intent have a non-color cue? |
| State | Are hover/focus/selected/busy/error/disabled combinations clear and stable? |
| Content | Do long labels, realistic data, empty/error cases and translated text fit? |
| Responsive | Does the layout reflow purposefully without shrinking text or losing actions? |
| Interaction | Are actions discoverable, targets usable and feedback immediate/understandable? |
| Motion | Is animation purposeful, bounded and reduced-motion aware? |
| Consistency | Does this component look related to the other components in the same screen? |

Review light/dark, roots 16/18/20, default/compact density, phone/tablet/desktop,
RTL and enlarged text where relevant. Use manual gallery inspection and focused
behavior/dimension checks. This plan does not add goldens as a workstream.

Keep the existing checks passing when implementing code. Add targeted functional
regressions for changed behavior, including root-aware helper parity, local
palette propagation, loading interaction, form lifecycle and narrow layouts.
Do not create arbitrary test-count requirements instead of checking behavior.

## 11. README and documentation changes

Replace the stale "first milestone only" README with the actual current state:
typed units, complete token families, broad implemented component areas, gallery
and pilots, local workspace usage, and this next UI-focused plan. Use a runnable
example with current `FwCard(content: ...)` and `FwButtonVariant.solid` APIs.

Clearly distinguish implemented features from proposals. Keep package names and
the experimental local-development status honest. Do not promise pub.dev
availability, all-platform certification or senior-design polish before verified.

This documentation update does not change application code or silently mark the
work above implemented. The existing plans remain available as history and
broader scope; this is the current UI enhancement direction.

## 12. Completion criteria for this improvement track

1. Token helpers agree on root/spacing behavior; intentional fixed exceptions
   are named and documented.
2. Built-in typography, icon, control and surface recipes produce a coherent
   family, without requiring consumer customization.
3. The observed dark-preview foreground issue and scoped button-palette mismatch
   are resolved; interaction-state contrast is reviewed in real surfaces.
4. Every shipped family has a recorded review against the checklist, with known
   remaining problems named rather than hidden behind a global polish claim.
5. Selected new building blocks simplify genuine compositions and reuse existing
   behavior instead of multiplying similar APIs.
6. The three showcase examples demonstrate a convincing composed UI with realistic
   content, consistent hierarchy and functional states.
7. Existing functional checks remain green; this track introduces no golden-test
   program, consumer customization system or release-engineering expansion.

## 13. Reference material

- [Material 3 typography](https://m3.material.io/styles/typography/type-scale-tokens)
  and [color](https://m3.material.io/styles/color/overview).
- [Material 3 buttons](https://m3.material.io/components/buttons/overview).
- [Bootstrap spacing](https://getbootstrap.com/docs/5.3/utilities/spacing/),
  [typography](https://getbootstrap.com/docs/5.3/content/typography/) and
  [forms](https://getbootstrap.com/docs/5.3/forms/overview/).
- [Preline component documentation](https://preline.co/docs/) as a reference for
  coherent patterns and state coverage, not copied Flutter implementation.
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/) for relevant readability, focus and
  interaction requirements; whole-application conformance needs its own evidence.

Bootstrap spacing and the Material typography entry page were reachable during
this review. Other links are reference resources, not a claim that every page
was fetched or that this document performs a formal standards audit.
