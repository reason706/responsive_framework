# Install

## Requirements

- Flutter **3.35.4** / Dart **3.9** (see [supported platforms](platforms.md)).
- No native plugins required: the framework is pure Dart + Flutter widgets.

## Add the dependency

Use the umbrella package for the whole framework:

```yaml
dependencies:
  fw: ^0.1.0
```

Or depend on individual packages to trim what you ship:

```yaml
dependencies:
  fw_core: ^0.1.0       # tokens, theme, lengths, metrics
  fw_layout: ^0.1.0     # stacks, wrap, grids, responsive builders
  fw_components: ^0.1.0 # the widget catalog
  fw_utilities: ^0.1.0  # debouncer, formatters, clipboard helpers
```

`fw` re-exports all four, so `import 'package:fw/fw.dart';` is the only
import most apps need. See [umbrella vs individual packages](packages.md).

## Fetch

```bash
flutter pub get
```

## Verify

```bash
flutter analyze
flutter test
```

Continue with [application setup](app-setup.md).
