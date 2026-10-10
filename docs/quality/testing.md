# Testing

## What to test per component

- **Unit**: token math, domain validation, state machines, contrast.
- **Widget**: real interaction (tap, drag, type), focus, form lifecycle,
  semantics flags. Use fixed logical surfaces; set
  `tester.view.physicalSize` for width tests and restore it after.
- **Stress**: 320px width + 2× text + RTL — the gallery rig runs this
  over the catalog; new components must pass it.

## Running

```bash
dart run melos run check   # format + analyze --fatal-infos + tests + web build
```

## Conventions

- One test file per component area (`button_test.dart`, `field_test.dart`).
- Semantics assertions use Flutter 3.35 getters (`.isButton`, `.isHeader`).
- Target tooltips, not glyphs, for icon assertions.
- Async tests use fake timers; never `Future.delayed` with real time.
- Golden tests: representative light/dark, states, narrow/wide, RTL,
  large text — pinned rendering, reviewed diffs.

## Manual

TalkBack/VoiceOver and desktop screen-reader paths are manual: record
platform, browser/version, and behavior. Automated matchers are partial
proof. See [platform matrix](platform-matrix.md).
