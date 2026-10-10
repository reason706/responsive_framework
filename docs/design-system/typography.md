# Typography

Type is set by **role**, not by size. `FwTextRole` covers the scale:

`displayLg, displaySm, h1–h6, lead, body, bodySm, caption, label, code`

```dart
FwText('Welcome', role: FwTextRole.h1)
```

## Rules

- Roles resolve to declared (unscaled) sizes. The OS text scaler is applied
  exactly once by Flutter — the framework never pre-scales font sizes, so
  changing the root size does not change text size.
- `FwText` sets `heading: true` semantics for heading roles; use it so
  screen readers get a proper heading structure.
- `maxLines`/`overflow` belong on `FwText`; truncation without an
  accessible alternative (tooltip, expand) is a defect.
- `FwText.rich` / `FwTextSegment` compose emphasized runs without leaving
  the role system.

## Custom fonts

Register fonts in your app's `pubspec.yaml` and point the theme at them
(see [custom fonts](../theming/fonts.md)). The gallery bundles Roboto
(Regular/Medium/Bold, with license) as its offline default.

Font licensing is the app's responsibility: only ship fonts you are
licensed to distribute. See [media](../media.md#font-licensing).
