# Implementation roadmap

## Milestone 1: Foundation

- [x] Flutter 3.35.4 pin and checksum-verifying Linux SDK installer.
- [x] Pub workspace, Melos commands, package boundaries, GitHub CI definition.
- [x] Seed-based light/dark tokens and Material theme adapter.
- [x] Required-base responsive values and validated breakpoint thresholds.
- [x] Explicit container/viewport scopes and parent-width grid.
- [x] Fixed/fluid container, typed box styling and spacing helpers.
- [x] Primary/outline/ghost button, loading/disabled states, noninteractive card.
- [x] Interactive gallery: width, brand, theme, RTL, text scale, actions.
- [x] Unit/widget tests for foundational behavior.

Implementation checkboxes describe authored features. Check results are recorded
separately; CI configuration is not evidence that GitHub Actions has run.

## Milestone 2: MVP completeness

- Complete typography, shadows, borders, and interaction token groups.
- Design partial component styles and local/global override precedence.
- Add heading/text, badge, and input with validation/controller lifecycle tests.
- Add horizontal/vertical stacks, auto-fit grids, and visibility policies.
- Add a complete responsive form/card recipe and copyable source examples.
- Add deterministic golden tests and browser integration tests.
- Test reduced-motion behavior, keyboard traversal, contrast and semantics.

## Milestone 3: Forms and feedback

- Checkbox, radio, switch, select, helper/error presentation.
- Alert, progress, dialogs, drawers; document focus restoration and dismissal.
- Responsive control sizes only where their behavior is well specified.
- Test localization, screen-reader feedback, and mobile keyboard behavior.

## Milestone 4: Navigation and data

- Tabs, navigation rail/sidebar, breadcrumbs, pagination.
- Menus/popovers with keyboard and overlay focus management.
- Tables and responsive data presentations.
- Adaptive dashboard and master-detail recipes.

## Release gates

Select public package names and a license. Validate installation in a clean app,
run device/browser integration, establish performance baselines, write API docs,
run publication dry runs, and document platform limitations before 0.x release.
Stabilize through real application use before 1.0. Token import, persistent theme
adapters, CLI, and generated string-class syntax stay outside the initial MVP.
