# Brand presets

`FwTheme.presets` ships 14 tested presets:

| Preset | Light | Dark |
|---|---|---|
| Light / Dark | ✅ | ✅ |
| Light · High contrast / Dark · High contrast | ✅ | ✅ |
| Light · Compact / Light · Comfortable | ✅ | — |
| Ocean / Forest / Sunset / Monochrome | ✅ | ✅ |

```dart
FwTheme.ocean().toThemeData()                              // light
FwTheme.ocean(brightness: Brightness.dark).toThemeData()    // dark
```

Each brand preset takes a `brightness` parameter and documents a light/dark
value-swap policy: the same token keys carry different values per
brightness. High contrast is a separate cross-brand policy (7:1 text
targets), not a brand.

## From a seed

```dart
FwTheme.fromSeed(seed: const Color(0xFF6750A4))
```

Seed-generated schemes derive the full Material 3 tonal palette. Prefer
presets for production; seeds are for exploration.

## Guarantees (all tested)

- Key-parity: every preset exposes identical token keys.
- Contrast floors: brand text pairs ≥ 4.5:1.
- No unchecked raw color combinations: all colors flow through `FwColors`.
