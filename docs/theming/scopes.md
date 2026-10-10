# Component & local scopes

`FwThemeScope` overrides the theme for a subtree:

```dart
FwThemeScope(
  theme: FwTheme.dark(),
  child: const FwCard(child: Text('Always dark here')),
)
```

Use for inverse surfaces, dense regions (`FwTheme.light(density:
FwDensity.compact)`), and brand moments. Components read
`context.fwTheme` — the nearest scope wins; there is no global.

State styles (hover/focused/pressed/disabled/selected) resolve inside the
active scope, so an inverse card's buttons automatically use the dark
state palette. See [state styles](state-styles.md).
