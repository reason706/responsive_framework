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
| `fw_layout` | Stacks, wrap, auto-fit grid, responsive builders, visibility, insets | `fw_core` |
| `fw_utilities` | `FwBox`, `FwStyle`, spacing extensions | `fw_core` |
| `fw_components` | The full widget catalog | `fw_core`, `fw_layout`, `fw_utilities` |

Depend on `fw_core` alone if you only need tokens/theming (e.g. a design-token
consumer or a code generator). Depend on `fw_components` if you need widgets
but want to exclude the umbrella re-export layer.

Dependency direction is always inward: components → layout/utilities →
core. Nothing depends on `fw`.
