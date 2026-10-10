# Contribute

## Architecture

```
packages/fw_core       tokens, theme, lengths, metrics (no dependencies)
packages/fw_layout     stacks, grids, responsive builders (→ fw_core)
packages/fw_utilities  box decoration, spacing helpers (→ fw_core)
packages/fw_components widget catalog (→ core, layout, utilities)
packages/fw           umbrella re-export (→ all)
apps/gallery          interactive docs & recipes (→ fw)
```

Dependency direction is always inward. `fw_token_gen` is the build_runner
token codegen (dev-only).

## Local checks

```bash
dart run melos run check   # format + analyze --fatal-infos + tests + web build
```

Toolchain: Flutter 3.35.4 / Dart 3.9 under `~/.fw-tools` (see repo
`tool/activate.sh` — export `FW_TOOLS_ROOT` manually; the script's default
is wrong).

## New-component checklist

1. Read `docs/planning/components.md` for the ID and contract.
2. API: `Fw*` prefix, token-based styling, logical start/end slots,
   `*Style` theme extension + `*StyleDelta` where applicable.
3. Five-board gallery doc: Anatomy / Properties / Layout / Usage / Accessibility.
4. Tests: unit + widget + semantics; 320px/2×-text/RTL stress passes.
5. Docs: add to `docs/components/overview.md` index.
6. `dart run melos run check` fully green.

## PR / release flow

- Small, reviewable milestones on a feature branch; one concern per commit.
- `CHANGELOG.md` entry per user-facing change.
- Versioning: semver per package; tokens and components version together
  until 1.0.
- Deprecation policy: `@Deprecated` with migration note; removal after
  two minor versions, never in a patch.

## Issue reporting

Include: package + version, Flutter version, minimal repro (preferably a
widget test), expected vs actual, platform. Accessibility issues are
treated as defects, not enhancements.
