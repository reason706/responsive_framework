# Complete framework implementation plan

Status: **planning only**. The code baseline is commit `93182bf` on GitHub `main`.
Everything described as proposed below is future work, not an available API.
The first foundation milestone already exists; this plan expands it through a
usable MVP, production beta, and a deliberately scoped 1.0 release.

## Read this plan in order

1. [Design system, responsive units, spacing, typography, and themes](design-system.md).
2. [Component catalog and implementation contracts](components.md).
3. [Implementation sequence, documentation, testing, and final release](delivery.md).
4. [Research sources, comparisons, and decisions](research.md).

The catalog explains what to add and how each family behaves. The design-system
specification explains how those widgets share sizing and visual rules. The
delivery plan turns both into ordered, reviewable implementation tasks.

The catalog contains **103 planning entries**: **79** marked MVP/1.0 and **24**
deferred or optional entries. These include component families, recipes and
adapters; they are not a claim that 103 separate widgets must be published.

## Product definition

Build a Flutter framework with Bootstrap's coherent layout/component approach
and Preline's broad application UI patterns, expressed through typed Flutter
APIs. Developers should compose interfaces quickly without adopting CSS, a
mandatory state-management library, a backend, or a large plugin bundle.

The design system must work on phones, tablets, desktop windows, and web panels;
changing a brand, font, base unit, density, or color mode should update the
appropriate parts consistently. Every control must account for touch, pointer,
keyboard, semantics, RTL, text scaling, and reduced motion where applicable.

## What exists and what is missing

| Area | Current foundation | Planned completion |
| --- | --- | --- |
| Workspace | Five library packages, gallery, Flutter pin, Melos, CI definition | Release conventions, API docs, compatibility matrix, examples |
| Theme | Seed-generated Material colors; light/dark; basic spacing/radii | Full semantic roles, component themes, font families, density, root metrics, presets |
| Responsive | Required-base values, six breakpoints, explicit query scopes | Fluid values, typed lengths, responsive spacing/typography, visibility policies |
| Layout | Fixed/fluid container, wrapping 12-column grid | Stacks, auto-fit grid, slivers, adaptive scaffold, safe-area/keyboard recipes |
| Styling | Typed decorated box and two spacing extensions | Directional typed insets, effects, constraints, text helpers, style precedence |
| Actions | Primary/outline/ghost button, disabled/loading, keyboard support | Sizes, icons, danger/success, groups, split/toggle buttons, busy progress |
| Content | Noninteractive card | Text/headings, links, badges/chips, images, avatars, lists, empty states |
| Forms | Native controls appear in the gallery only | Actual framework fields, validation, select, slider, date/time, advanced input |
| Feedback | Button loading text only | Progress, spinner, skeleton, alerts, toast, dialog, drawer |
| Navigation/data | Not implemented | Tabs, sidebar, navbar, breadcrumbs, stepper, menus, table, timeline |
| Verification | 23 passing unit/widget tests and a local Chromium smoke | More behavior tests, deterministic goldens, browser/device integration, profiling |

Native Flutter sliders and switches used by the gallery are demonstrations,
**not** framework slider/switch components. The current theme is a foundation,
**not** a completed rem-based or fluid typography system.

## Release scope

| Stage | Meaning | Required outcome |
| --- | --- | --- |
| Foundation | Current implementation | Theme/grid/button/card vertical slice |
| MVP | First usable 0.x package release | Root-relative units, text, actions, layout, basic forms, media identity, basic progress/feedback, working recipes |
| Beta | Broader 0.x releases | Overlays, advanced forms, navigation, data display, platform verification |
| 1.0 | Stable supported framework | Every catalog entry tagged `1.0` or `MVP`, release gates, documentation, real-app pilot validation |
| 1.x | Optional future additions | Entries explicitly tagged `1.x`; not blockers for 1.0 |
| Adapter | Independently versioned integration | Optional plugins and provider integrations; never mandatory for core |

`MVP` entries also belong to 1.0. Some advanced rows contain a basic 1.0 feature
and a clearly identified later extension; only the basic behavior is required.
Recipes compose existing components and do not automatically create new public
widgets for every visual variation.

## Main decisions

- Use a stable 16-logical-pixel root by default; represent typography and spacing
  as multiples of that root. Allow an explicitly configured responsive root.
- Make headings and large section gaps fluid within bounded minimum/maximum
  values; preserve readable body/control defaults at narrow widths.
- Let Flutter apply its `TextScaler` once. Do not multiply all layout dimensions
  by the system font scale or scale the entire application like a screenshot.
- Keep breakpoints in logical pixels to avoid unit-resolution cycles.
- Build on Flutter's existing rendering, text, focus, form, and overlay tools;
  create custom render objects only after a measured need.
- Keep backend operations, authentication, upload transport, persistence, and
  application state out of the core component layer.
- Provide optional adapters for file picking, SVG, charts, maps, and similar
  features rather than forcing those dependencies on every application.
- Make defaults accessible, but report exact test coverage rather than claiming
  that any application using the framework automatically meets WCAG.

## Definition of success

A developer can install the framework, build a responsive settings/form page
and dashboard, change fonts/branding/root units once, and retain sensible
layouts, semantics, keyboard navigation, RTL, and large-text behavior. Another
developer can extend a component without reverse-engineering styling rules.

The release includes understandable documentation, reproducible examples,
known limits, upgrade instructions, and measured performance baselines. Stars,
downloads, and a large widget count do not replace those technical outcomes.

## How to use the backlog

The component IDs in the catalog are stable planning references, not package
symbols. Work should proceed by dependency and risk, not by alphabetical order.
Each implementation PR must reference its task/component ID, document any
change to this plan, and meet its applicable definition of done.

Recommended next coding task: implement **DS-01 through DS-05** from the delivery
plan, prove their behavior in the existing button/card/grid gallery, and review
the public API before multiplying it across the component catalog.
