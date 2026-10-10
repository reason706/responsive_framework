# Component / state matrix

Standard states every interactive component supports (where applicable):

| State | Meaning | Test |
|---|---|---|
| default | Resting | visual |
| hover | Pointer over (desktop/web) | widget |
| focused | Keyboard focus, ring visible | widget + semantics |
| pressed | Active press | widget |
| disabled | Non-interactive, reduced emphasis | widget + semantics |
| selected | Chosen in a set | widget + semantics |
| loading | Busy, blocks re-entry | widget (fake async) |
| error | Invalid, still interactive | widget + semantics |

Per-component variant × state boards live in the gallery
(`apps/gallery/lib/catalog.dart`); the [catalog index](../components/overview.md)
maps IDs to components.

## Upgrade guides

- **0.1 → 0.2**: `FwButtonSize` → `FwSize` (enhancement merge);
  button `icon`/`iconPosition` replace `leading`/`trailing` widget slots
  (migration codemod notes in [migration](../migration.md)).
- Token renames, if any, are listed here with the version they landed in.

## Known issues

- Web: first-paint font swap until fonts load (use `FontLoader` /
  bundled fonts to mitigate).
- `FwShow` with `retain` mode has documented runtime cost — prefer
  `remove` for rarely-shown content.
- Goldens are pinned to the CI renderer; local diffs need review, not
  blind acceptance.
