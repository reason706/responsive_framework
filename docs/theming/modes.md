# Light / dark / system choice

```dart
MaterialApp(
  theme: FwTheme.light().toThemeData(),
  darkTheme: FwTheme.dark().toThemeData(),
  themeMode: ThemeMode.system,
)
```

`toThemeData()` maps the framework theme onto Material 3 `ThemeData`, so
Material widgets inherit the same tokens. `themeMode` follows the OS by
default with `ThemeMode.system`; the gallery exposes a manual toggle for
testing.

Rules:

- Never branch widget code on `Brightness` — read semantic roles; the
  preset supplies the right values.
- Persist the user's choice in the app (the framework doesn't own
  storage); re-apply on startup before first frame to avoid a flash.
- Test both modes in the gallery toggle and in widget tests where color
  carries meaning (error states, charts).
