# Visibility & state retention

`FwShow` / `FwResponsiveBuilder` conditionally build subtrees by breakpoint:

```dart
FwShow(
  above: FwBreakpoint.md,
  mode: FwVisibilityMode.retain, // keep state while hidden
  child: const Sidebar(),
)
```

Rules:

- Hiding a subtree must not destroy its state unless the design intends
  it — `FwVisibilityMode.retain` keeps the child mounted (with a
  documented runtime cost); `remove` unmounts.
- The adaptive scaffold (L09) preserves destination selection, field
  state, detail selection, and scroll position across responsive
  transitions — tested.
