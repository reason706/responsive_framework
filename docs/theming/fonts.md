# Custom fonts

Register fonts in the app's `pubspec.yaml`, then reference them from your
theme's typography. The framework resolves `FwTextRole`s through whatever
family the theme declares — no widget changes needed.

```yaml
flutter:
  fonts:
    - family: BrandSans
      fonts:
        - asset: assets/fonts/BrandSans-Regular.ttf
        - asset: assets/fonts/BrandSans-Bold.ttf
          weight: 700
```

Rules:

- Ship only fonts you are licensed to distribute (see
  [font licensing](../media.md#font-licensing)).
- Prefer variable fonts where licensing allows; otherwise bundle the
  weights you actually use (Regular/Medium/Bold covers most catalog
  needs — the gallery's Roboto bundle is the reference).
- Test at 2× text scaling: custom fonts must not clip descenders or break
  line-height at large sizes.
- The W3C token export carries family names as data; keep them identical
  across platforms.
