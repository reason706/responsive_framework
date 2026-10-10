# Shapes & shadows

## Radii

`FwRadii` — the corner-radius scale, root-relative. Components take radius
from the theme; per-instance radius overrides accept the same scale.

## Elevation

`FwElevation` levels 0–5 map to surface-tint + shadow pairs:

```dart
Container(decoration: const FwElevation().decoration(context, 2))
```

Levels outside 0–5 throw `RangeError` (tested).

## Rules

- Overlays, dialogs, sheets, and menus consume elevation tokens — never
  raw `BoxShadow` (enforced by test; raw shadows live only in `FwShadows`).
- Elevation communicates hierarchy, not decoration: content < raised
  controls < overlays < modals.
- Dark themes shift emphasis to surface tint over shadow, per the token
  values — components don't branch on brightness themselves.
