# High contrast

`FwTheme.highContrastLight()` / `highContrastDark()` raise text pairs to
7:1 and strengthen non-text indicators (borders, focus rings, selected
states) so meaning never depends on color alone.

```dart
FwTheme.highContrastLight().toThemeData()
```

Rules:

- Every component must remain fully usable in high-contrast presets —
  the gallery preset picker is the manual test rig.
- Status and validation always pair color with an icon or text
  (`FwAlert`, `FwStatusDot` with labels), never color alone.
- Respect the OS "high contrast" / "increase contrast" setting by
  offering the preset where your app exposes theme choice.
