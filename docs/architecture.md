# Foundation architecture

## Scope

This milestone establishes the workspace, theme/response contract, grid, typed
styling, button, card, and gallery. It does not implement the full component
catalog in the original report.

## Dependencies

`fw_layout`, `fw_utilities`, and `fw_components` depend on `fw_core`. They do not
depend on each other. `fw` re-exports their public APIs. The gallery depends only
on `fw` and Flutter. Core uses Flutter's theme APIs; it is not a pure Dart package.

Use the existing checkout for development. Cloud tasks are already isolated;
there is no need to create Git worktrees for setup.

## Responsive contract

`Responsive<T extends Object>` requires `base`. Each non-null override takes
effect at its threshold and remains effective until another override replaces
it. Breakpoint detection uses logical pixels, includes exact thresholds, and
rejects invalid widths or unordered thresholds. Nullable resolved values are
not supported by this first API.

`FwContainerQuery` measures bounded parent width. `FwViewportQuery` explicitly
uses MediaQuery viewport width. Context resolution requires a scope and never
silently substitutes the screen for a missing container. Nested scopes win.
`FwRow` establishes its own container scope; it always sizes spans against the
width it actually has. Unbounded grid/query width is an error with setup guidance.

## Grid contract

For available width W and gutter g:

```
cell = (W - 11g) / 12
item = span * cell + (span - 1) * g
```

Wrap inserts gutters between items and starts another run when needed. At tiny
widths g is capped at W / 11 so cells do not become negative. Widths are capped
at W to avoid floating-point overflow for full spans. All configured spans must
be 1–12, including overrides that are currently inactive. Children remain in
source order. RTL changes placement, not logical semantics order.

Fixed container max widths are responsive values configurable independently of
thresholds. Their padding is inside the max width, so a grid uses the remaining
content width. Offsets, auto spans, equal-height runs, and visual reordering are
deferred. Start with standard Flutter layout widgets; profile before introducing
a custom render object.

## Theme contract

Install a `FwTheme` extension, preferably with `toThemeData()`, which maps its
ColorScheme and TextTheme into Material. Missing registration produces an
actionable error. Material-backed components require a Material application
context; this milestone does not provide a standalone Cupertino adapter.

Semantic colors come from Flutter's seed color algorithm. The initial scale
includes spacing and radii. Numeric and color tokens interpolate; breakpoint
sets switch discretely during theme animation. Persistence belongs in the
application. Custom token import, component theme scopes, shadows, and the full
typography scale remain future work.

Core semantic text-pair contrast is tested for the example seeds in both themes.
Arbitrary overrides, disabled content, backgrounds with images, and entire
applications require their own accessibility validation.

## Styling contract

`paddingAll(16)` means sixteen logical pixels; `paddingToken(FwSpace.s4)` means
a named theme token. Extensions create wrappers and ordering matters.
`FwBox` puts decoration outside padding, uses directional insets, and does not
clip child content implicitly. There is no CSS parser or CSS margin collapse.

## Component contract

Buttons use Flutter Material button primitives for semantics, focus, pointer,
keyboard, and disabled-state behavior. The framework sets token-based sizing,
padding, radius, and focus outlines. Loading disables activation; supply a
localized `loadingLabel` for useful live-region feedback. This first loading
state uses text, not an animated spinner.

Cards are noninteractive surfaces. Interactive card semantics, hover behavior,
and keyboard handling need a separately designed API. There are no hard-coded
application strings in library widgets. Gallery copy is example application UI.

## Validation and release boundaries

CI checks format, analyzer, package/widget tests, and a web release build.
Tests use fixed logical sizes and restore the test view after each resize.
Gallery widget tests exercise real component actions and state changes; they
are not a substitute for browser/device integration tests.

The gallery bundles Roboto with its upstream license and builds with local
CanvasKit resources. Its demonstrated Latin text does not require Google Fonts
at runtime. Wider language coverage requires additional explicitly licensed
font assets; RTL placement tests alone do not establish Arabic/Hebrew coverage.

Provisional packages cannot be published (`publish_to: none`). Choose a license
and available names before release. Do not claim mobile platform readiness from
web tests. Goldens, device integration, performance budgets, and publication
checks belong to later release gates.
