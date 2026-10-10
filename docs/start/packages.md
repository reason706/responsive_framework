# Umbrella vs individual packages

## `fw` — the umbrella (recommended)

```yaml
dependencies:
  fw: ^0.1.0
```

```dart
import 'package:fw/fw.dart';
```

Re-exports `fw_core`, `fw_layout`, `fw_utilities`, and `fw_components`.
Use it unless you have a reason not to: one version to track, no
import juggling.

## Individual packages

| Package | Contents | Depends on |
|---|---|---|
| `fw_core` | Tokens (spacing, color, type, radius, shadow, motion, elevation, haptics, grid), `FwTheme`, lengths, metrics, W3C token export | — |
| `fw_layout` | Stacks, wrap, auto-fit grid, responsive builders, visibility, insets, adaptive scaffold | `fw_core`, `fw_components` * |
| `fw_utilities` | `FwBox`, `FwStyle`, spacing extensions | `fw_core` |
| `fw_components` | The full widget catalog | `fw_core`, `fw_layout`, `fw_utilities` |

\* Layering note: `fw_layout`'s `FwAdaptiveScaffold` composes the navigation
components, so `fw_layout` depends on `fw_components`. The intended direction
is components → layout → core; the adaptive scaffold is the one exception
(a future refactor may move it into `fw_components` to restore strict
layering). If you need layout primitives without the component catalog,
import the specific `fw_layout/src/` libraries directly rather than the
package barrel.

Depend on `fw_core` alone if you only need tokens/theming (e.g. a design-token
consumer or a code generator). Depend on `fw_components` if you need widgets
but want to exclude the umbrella re-export layer.

Dependency direction is inward (nothing depends on `fw`), with the one
documented exception above.
