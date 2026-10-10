# Responsive scopes

A scope overrides theme values for a subtree without affecting the rest of
the app. Scopes compose: root → app theme → local scope.

```dart
FwThemeScope(
  theme: FwTheme.dark(),
  child: const FwCard(child: Text('Always dark')),
)
```

Use scopes for:

- Inverse surfaces (a dark card on a light page).
- Density changes in dense regions (data tables inside a comfortable app).
- Brand moments (a marketing banner in the Ocean preset inside a
  Monochrome app).

Rules:

- Scopes inherit the root metrics unless they explicitly override them —
  changing the root inside a scope re-scales that subtree only.
- Components read `context.fwTheme`; they never reach past the nearest
  scope. There is no global singleton.
- Prefer presets (`FwTheme.ocean()`, …) over hand-built themes so token
  key-parity is preserved.

See [component & local scopes](../theming/scopes.md).
