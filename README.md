# Flutter Responsive UI Framework

A modular Flutter UI framework with shared design tokens, root-relative sizing,
parent-aware responsive layouts, and a growing set of ready-made components.

The project has moved beyond its initial button/card/grid foundation. The current
implementation includes forms, pickers, media, navigation, overlays, feedback,
data display, adaptive controls, and complete example applications.

**Current direction:** improve the built-in UI's visual quality, token/utility
consistency, component defaults, and useful composition features. Read the
[UI Improvement and Feature Enhancement Plan](docs/planning/ui-feature-enhancement-plan.md).
That plan is proposed work; this documentation update does not implement it.

## What is implemented

| Area | Available capabilities |
| --- | --- |
| Design tokens | Semantic colors, light/dark and named presets, high-contrast presets, spacing, radii, borders, icons, opacity, elevation, motion and haptics |
| Responsive sizing | Typed logical-pixel/rem/em lengths, bounded fluid values, mobile-first overrides, root metrics, viewport and container scopes |
| Typography | Text roles, fluid headings, numeric typography, rich text, links, code/keyboard helpers and read-more content |
| Layout | Fixed/fluid containers, twelve-column grid, auto-fit grid, stacks, wrap/inline, token gaps/padding, visibility, scrolling and adaptive panes |
| Actions | Button treatments and intents, icon actions, groups, segmented/split buttons, async buttons, FAB/speed dial and gesture confirmations |
| Forms | Text/password/search/textarea, checkbox/radio/switch/select, sliders/ranges, number/date/time/phone/OTP/tag inputs, async validation and form coordination |
| Media | Responsive images, figures, avatars/groups, carousel, photo viewer, icons and QR display |
| Feedback | Alerts, banners, toast, notification UI, progress, gauges, task progress, skeleton/shimmer and empty/error states |
| Overlays and navigation | Dialog/sheet/drawer/side sheet, menu/popover/tooltip/hover card, command palette, tabs, sidebar, bottom navigation, rail, breadcrumb and stepper |
| Data and interaction | Tables with responsive presentation, lists, accordion, timeline, stats, tree view, calendar, rating, reorder/swipe/refresh and resizable panels |
| Examples | Interactive gallery plus settings, dashboard and marketing pilot applications |

These are implemented experimental APIs, not a claim of complete production
polish or verified support on every Flutter platform. Some wrappers and local
scope behavior need integration improvements documented in the new plan.

## Design principles

- **Shared defaults:** colors, type, shape and spacing should make components
  look related without per-widget restyling.
- **Root-relative layout:** `1rem` follows the configured design root; fixed
  logical pixels remain explicit.
- **Parent-aware responsiveness:** reusable regions can respond to their
  available width through container queries.
- **Accessible text behavior:** root sizing, responsive layout and Flutter's
  system TextScaler remain separate; text scaling is applied once.
- **Composition:** widgets expose content/state/callbacks and reuse Flutter
  primitives for text editing, focus, gestures and rendering.
- **Useful states:** disabled, busy, selected, focused, invalid and empty states
  belong to the component experience.

## Start developing

Flutter **3.35.4** / Dart **3.9.2** is the pinned toolchain. The provided installer
supports Linux x64 and stores the SDK and caches outside the checkout.

```sh
bash tool/install.sh
source tool/activate.sh
dart run melos run check
```

Installation requires GitHub, `pub.dev` and `storage.googleapis.com`. The SDK
archive is verified against Flutter's official release manifest. Dependency
resolution enforces the committed root workspace lockfile. On other development
platforms, install the pinned SDK and use the same pub workspace.

### Run the gallery

From the repository root:

```sh
source tool/activate.sh
cd apps/gallery
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --no-web-resources-cdn
```

The gallery includes foundations, component documentation, interaction demos and
recipes. It has root-size, text-scale, width, color-mode and RTL controls. The
web build uses local CanvasKit resources and bundled example fonts. Additional
script/font coverage is documented separately.

## A working example

Import the umbrella package and install a theme plus responsive scope. Current
cards use `content`, `header` and `actions` slots.

```dart
import 'package:flutter/material.dart';
import 'package:fw/fw.dart';

void main() => runApp(const FrameworkExample());

class FrameworkExample extends StatelessWidget {
  const FrameworkExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: FwTheme.ocean().toThemeData(),
    darkTheme: FwTheme.ocean(brightness: Brightness.dark).toThemeData(),
    themeMode: ThemeMode.system,
    home: const FwViewportQuery(child: ExamplePage()),
  );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  int actionsCompleted = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Framework example')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: FwContainer(
          child: FwRow(
            children: [
              FwCol(
                span: const Responsive(base: 12, md: 6),
                child: FwCard(
                  header: const FwText(
                    'Ready-made UI',
                    role: FwTextRole.h2,
                    heading: true,
                  ),
                  content: FwText('Actions completed: $actionsCompleted'),
                  actions: FwButton(
                    label: 'Try the action',
                    onPressed: () => setState(() => actionsCompleted++),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

For another design root, use the existing API:
`FwTheme.ocean().copyWith(metrics: const FwMetrics(rootSize: 18))`.
Typography and spacing resolve through their appropriate scopes; this does not
multiply all layout dimensions by the operating system's text scale.

## Repository structure

| Package / application | Responsibility |
| --- | --- |
| `packages/fw_core` | Tokens, themes, metrics, typed lengths, responsive values and shared vocabularies |
| `packages/fw_layout` | Layout primitives, containers/grids and adaptive composition |
| `packages/fw_utilities` | Spacing/decoration helpers, formatting and async utilities |
| `packages/fw_components` | Ready-made UI components and their interaction models |
| `packages/fw` | Curated umbrella exports |
| `packages/fw_token_gen` | Token-source builder and generated Dart/JSON output |
| `apps/gallery` | Component catalog, foundations and recipes |
| `apps/settings_app`, `apps/dashboard_app`, `apps/marketing_app` | Pilot applications consuming public exports |

Library names are provisional and packages currently use `publish_to: none`.
Use the local workspace; the README does not claim pub.dev availability.

## Documentation and next steps

- [Current UI improvement and feature plan](docs/planning/ui-feature-enhancement-plan.md)
  — built-in defaults, tokens/utilities, family polish and purposeful additions.
- [Documentation index](docs/README.md) — setup, design system, forms, layout,
  components and recipes.
- [Complete original implementation plan](docs/planning/README.md) — product
  scope, design contracts, catalog and implementation sequence.
- [Completed-work retrospective](docs/planning/completed-work-retrospective.md)
  — implementation history and verification receipts.
- [Improvement Plan 2](docs/planning/improvement-plan-2.md) — preceding token,
  spacing and hierarchy work; consult the retrospective for current status.

The next UI track addresses visual hierarchy, dark-surface legibility,
consistent spacing resolution, type/icon/control metrics, state presentation,
and more useful headers/groups/toolbars. It does not require a new consumer
customization system or a golden-test workstream.

## Verification status

At baseline `04d75f0`, a local `dart run melos run check` passed formatting,
analysis, **794 repository tests**, and the gallery web release build.
A subsequent Chromium visual review sampled the initial gallery and foundation
presets. That review found visual issues recorded in the new plan; functional
checks alone do not establish that every component is polished.

See the [platform matrix](docs/quality/platform-matrix.md) and
[pilot findings](docs/pilots/friction-log.md) for native/device limitations.
Native verification is incomplete. No full-platform certification or formal
accessibility compliance audit is claimed.
