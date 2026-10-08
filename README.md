# Flutter UI framework — foundation preview

A token-driven Flutter design system with parent-aware responsive layouts and accessible Material-backed components. This implements the first milestone, not the full component library.

## Setup

Flutter **3.35.4** (Dart 3.9) is pinned. The cloud installer targets Linux x64 and requires `storage.googleapis.com`, `pub.dev`, and GitHub.

```sh
bash tool/install.sh
source tool/activate.sh
dart run melos run check
```

The installer verifies the SDK archive against Flutter's HTTPS release manifest, stores the SDK/cache outside the checkout, and resolves the pub workspace. Once `pubspec.lock` exists, it enforces that lockfile. Commit the generated lockfile after successful dependency resolution. Never disable TLS or package hash checks.

## Gallery

```sh
source tool/activate.sh
cd apps/gallery
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --no-web-resources-cdn
```

The gallery demonstrates a responsive card grid, buttons, theme changes, a local width simulator, RTL, and text scaling. `flutter build web` creates a deployable build. Cloud onboarding does not expose localhost previews.

## Packages

| Package | Responsibility |
| --- | --- |
| `fw_core` | Themes, tokens, responsive values and query scopes |
| `fw_layout` | Containers and wrapping twelve-column grid |
| `fw_utilities` | Typed box styling and explicit spacing helpers |
| `fw_components` | Material-backed buttons and token-driven cards |
| `fw` | Curated umbrella exports |

Names are provisional; packages are marked `publish_to: none` until naming, licensing, and release review are complete. See [architecture](docs/architecture.md) and [roadmap](docs/roadmap.md).

The [complete implementation plan](docs/planning/README.md) details the proposed
rem-like unit system, responsive typography/spacing, complete theming, component
catalog, implementation order, documentation, tests, and release gates through 1.0.
It is planning documentation; those future APIs are not yet implemented.

## Example

```dart
MaterialApp(
  theme: FwTheme.light().toThemeData(),
  darkTheme: FwTheme.dark().toThemeData(),
  home: FwContainer(
    child: FwRow(
      children: [
        FwCol(
          span: const Responsive(base: 12, md: 6),
          child: FwCard(
            child: FwButton(label: 'Save', onPressed: save),
          ),
        ),
      ],
    ),
  ),
);
```

Import `package:fw/fw.dart` and Flutter Material. `dart run melos run check` checks formatting, analyzes, tests packages, and builds the gallery for web. CI uses the same workflow. Android/iOS, goldens, benchmarks, and publication remain later milestones.
