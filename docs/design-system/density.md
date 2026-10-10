# Density

`FwDensity` adjusts control sizing without changing the root:

- `compact` — dense data interfaces (tables, toolbars).
- `comfortable` (default) — regular apps.
- Spacious presets exist where the catalog needs them.

```dart
FwTheme.light(density: FwDensity.compact).toThemeData()
```

Rules:

- Density changes padding and control heights, never text size.
- Minimum touch target stays 48dp regardless of density — density must not
  break accessibility.
- Prefer a local `FwThemeScope` with a compact theme for dense regions
  rather than compacting the whole app.
