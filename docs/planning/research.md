# Research sources and design decisions

Research date: 9 October 2026 (Australia/Sydney). This record distinguishes
observed source behavior from recommendations for our Flutter framework.

## 1. Access and evidence

Direct requests to `preline.co/docs/` and `getbootstrap.com` returned HTTP 403 in
this cloud environment. Research used the projects' official GitHub sources,
not a claim of browsing every live documentation page. Public documentation
links below are useful references; source links identify the material inspected.

Preline source: `htmlstreamofficial/preline`, commit
`05ca59998db345cfede649b00093032409b37f25` (main snapshot).
Bootstrap source: `twbs/bootstrap`, **v5.3.8**, commit
`25aa8cc0b32f0d1a54be575347e6d84b70b1acd7`.
Flutter interpretation uses the installed **3.35.4** toolchain and its API/source
contracts. This plan does not upgrade the framework to Bootstrap's development
branch or claim that v5.3.8 is the newest release available.

## 2. Bootstrap findings

| Topic | Observed source behavior | Framework recommendation |
| --- | --- | --- |
| Root-relative sizes | `$font-size-base: 1rem`; default browser root is typically 16px | Explicit Flutter root metric, default 16 logical pixels; do not pretend a Flutter canvas inherits CSS rem |
| Spacing | `$spacer: 1rem`; default map uses 0, .25, .5, 1, 1.5, 3 multiples | Preserve our richer named scale as rem ratios, with a documented Bootstrap-equivalent mapping |
| RFS | Bounded resizing expressed through rem and viewport units; applies beyond font size | Separate fluid lengths from rem; support container width and min/max bounds |
| Breakpoints | Mobile-first responsive layout and spacing across six defaults | Retain explicit query scopes and logical-pixel thresholds |
| Themes | Color modes can apply globally or to a local component subtree | Component/theme scopes with property inheritance and native Material propagation |
| Images | Responsive image cannot exceed parent width; proportional height | Bounded provider-based images, aspect reservation, loading/error fallback |
| Progress | Determinate wrapper semantics; labels can be external for readability | Explicit progress domain + label semantics; external percentage label by default |
| Accessibility | Contrast and full application behavior depend on actual usage; reduced-motion support | Test defaults and behavior, avoid blanket compliance claims |

Our token `s3` is 0.75rem by default; Bootstrap's spacing class index `3` is
1rem. Token names are **not** Bootstrap class-number compatibility. Document the
mapping rather than silently reusing numerical names with different meanings.

Inspected Bootstrap sources:

- [Spacing](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/utilities/spacing.mdx)
  / [public docs](https://getbootstrap.com/docs/5.3/utilities/spacing/).
- [Typography](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/content/typography.mdx)
  / [public docs](https://getbootstrap.com/docs/5.3/content/typography/).
- [RFS](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/getting-started/rfs.mdx)
  / [public docs](https://getbootstrap.com/docs/5.3/getting-started/rfs/).
- [Sass variables](https://github.com/twbs/bootstrap/blob/v5.3.8/scss/_variables.scss).
- [Color modes](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/customize/color-modes.mdx)
  / [public docs](https://getbootstrap.com/docs/5.3/customize/color-modes/).
- [Images](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/content/images.mdx).
- [Progress](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/components/progress.mdx).
- [Range input](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/forms/range.mdx).
- [Accessibility](https://github.com/twbs/bootstrap/blob/v5.3.8/site/src/content/docs/getting-started/accessibility.mdx).
- [Documentation catalog](https://github.com/twbs/bootstrap/blob/v5.3.8/site/data/sidebar.yml).

## 3. Preline findings

The inspected official README lists layout/content, base components, navigation,
basic/advanced forms, overlays, tables and third-party integrations. It explicitly
includes avatars/groups, images, progress/upload progress, range slider, PIN,
combobox, number input, tree view, layout splitter, carousel, charts and editors.

Its plugin documentation separates interaction behavior from styling, and several
advanced plugins integrate other libraries. These patterns support our decision
to separate Flutter component contracts from optional provider/engine adapters.
HTML/JS plugins do not directly become Flutter widgets; reimplement behavior
using Flutter primitives and semantics rather than embedding a browser DOM.

| Source inspected | Relevant behavior | Flutter interpretation |
| --- | --- | --- |
| Component/plugin catalog | Broad UI families and third-party integration boundary | Comprehensive catalog with MVP/1.0/1.x/adapter tiers |
| Ocean theme CSS | Primary hover/focus/active/checked roles; component surfaces; dark overrides | Shared semantic roles, combined states and per-component theme defaults |
| Overlay README | Backdrop, focus trap, Tab/Escape, layering, responsive dismissal | One overlay/focus lifecycle contract before menus and advanced selects |
| Combobox README | Local/API suggestions, keyboard and item customization | Typed query/selection API; no mandatory network client; stale-result protection |
| Range slider README | Single/dual handles, formatting, disabled state, external slider library | Native Slider/RangeSlider first; advanced nonlinear/multi-handle behavior deferred |
| File-upload README | Preview/progress/multiple files and Dropzone integration | Optional picking/upload adapter plus pure task-progress presentation |
| Datepicker README | Locale/date/time configuration and calendar integration | Native date/time adapter first; full calendar explicitly separate |

Inspected Preline sources (pinned snapshot):

- [Official catalog and overview](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/README.md).
- [Ocean theme](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/css/themes/ocean.css).
- [Overlay](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/src/plugins/overlay/README.md).
- [Combobox](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/src/plugins/combobox/README.md).
- [Advanced range slider](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/src/plugins/range-slider/README.md).
- [File upload](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/src/plugins/file-upload/README.md).
- [Datepicker](https://github.com/htmlstreamofficial/preline/blob/05ca59998db345cfede649b00093032409b37f25/src/plugins/datepicker/README.md).

Public entry points: [Preline documentation](https://preline.co/docs/),
[themes](https://preline.co/docs/themes.html),
[component catalog links](https://github.com/htmlstreamofficial/preline#-tailwind-css-components).
Licenses differ across source/assets/products; review the applicable license
before copying anything. No Preline implementation/assets were imported here.

## 4. Flutter reference contracts

- [TextScaler](https://api.flutter.dev/flutter/painting/TextScaler-class.html):
  nonlinear scaling means a single multiplication factor is insufficient.
- [TextStyle](https://api.flutter.dev/flutter/painting/TextStyle-class.html):
  font size is logical pixels; height is a multiplier.
- [MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html):
  query size, text scaling and accessibility/motion settings selectively.
- [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html):
  typed extension and interpolation integration.
- [FormField](https://api.flutter.dev/flutter/widgets/FormField-class.html):
  value/validation/save/reset lifecycle.
- [Image](https://api.flutter.dev/flutter/widgets/Image-class.html):
  provider, semantics, fit, loading and decode considerations.
- [Slider](https://api.flutter.dev/flutter/material/Slider-class.html) and
  [RangeSlider](https://api.flutter.dev/flutter/material/RangeSlider-class.html):
  native control behavior to adapt before custom rendering.

These are reference links and API contracts, not a claim that every live API page
was fetched. Recheck signatures against the pinned SDK during implementation.

## 5. Decisions that supersede the initial report

1. Rem-relative sizing and fluid responsiveness are distinct features.
2. Typed values replace `Object`-accepting utility inputs.
3. System text scaling is preserved and applied once, including nonlinear scaling.
4. A root-responsive app is optional; default body/root sizing remains readable.
5. Component overrides are resolved per property and propagate to native primitives.
6. Standard Flutter grid composition remains until profiling demonstrates a need.
7. Theme preference persistence, upload transport and third-party engines are optional.
8. One shared field/progress/overlay/navigation contract precedes dependent widgets.
9. State/lifecycle/a11y tests happen while each component is built.
10. Scope includes a much broader catalog, so full-release estimates must increase.
11. Every proposed API is clearly separated from the existing foundation.
12. Stable 1.0 is gated by verified behavior and real use, not an arbitrary week.

## 6. Implementation-time decisions still open

Provisional defaults allow planning to continue. Before affected code lands,
record ADRs for: public package names/license; exact length constructor names;
font presets and script coverage; component-style nullable override mechanism;
date-only value type; controlled/uncontrolled field API; async suggestion loader
contract; table schema boundaries; optional plugin choices; minimum SDK/native
API support; docs-site tooling; supported platform/browser matrix.

These are implementation reviews, not reasons to stop writing this plan. Provider
credentials or deployment destinations are only needed when an actual optional
integration/deployment is requested; none are required for the local framework.
