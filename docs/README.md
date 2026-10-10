# responsive_framework — Documentation

The responsive Flutter UI framework: typed design tokens, theme presets,
and an atomic-tiered component catalog. All widgets resolve sizes against
a configurable root, keep accessibility text scaling separate, and apply
Flutter's `TextScaler` exactly once.

## Sections

| Section | Contents |
|---|---|
| [Start](start/install.md) | Install, supported SDK/platforms, app setup, first responsive page, umbrella vs individual packages |
| [Design system](design-system/units.md) | Units, fluid values, scopes, spacing, typography, color, density, motion, shapes/shadows |
| [Theming](theming/presets.md) | Brand presets, light/dark/system, local scopes, state styles, high contrast, custom fonts |
| [Layout](layout/containers.md) | Containers, grid, stacks/wrap, auto-fit, visibility, safe area, scrolling, adaptive panes |
| [Components](components/overview.md) | Every catalog family: overview, props, variants, states, responsive behavior, a11y |
| [Forms](forms/lifecycle.md) | Field lifecycle, validation timing, IME, reset/save, error summary, localization, async |
| [Media](media.md) | Image providers, responsive images, aspect reservation, decode/cache, CORS/offline/error, avatars, font licensing |
| [Recipes](recipes.md) | Complete recipe sources with expected behavior |
| [Adapters](adapters.md) | Optional adapters: installation, capabilities, platform limits |
| [Quality](quality/accessibility.md) | A11y responsibility, keyboard reference, text scaling, RTL, testing, profiling, platform matrix |
| [Reference](reference/tokens.md) | Generated API docs, token tables, component/state matrix, upgrade guides, changelog, known issues |
| [Contribute](contribute.md) | Architecture, local checks, new-component checklist, PR/release flow, issue reporting |

Also see: [Migration guide](migration.md) · [Pilots & friction log](pilots/friction-log.md)
· [Changelog](../CHANGELOG.md) · [Planning](planning/delivery.md)

## Conventions used in these docs

- Widget names use the `Fw` prefix (`FwButton`, `FwTextField`, ...).
- Code samples import only public API: `import 'package:fw/fw.dart';`
- Sizes are root-relative: at the default root of 16, `FwSpace.s4` == 16px.
  Accessibility text scaling (the OS text-size setting) is independent and
  applied exactly once via `TextScaler`.
- Every component page follows the five-board contract: **Anatomy**,
  **Properties** (variants × states), **Layout & spacing**, **Usage**
  (do / don't), **Accessibility**. The interactive versions live in the
  gallery app (`apps/gallery`).
