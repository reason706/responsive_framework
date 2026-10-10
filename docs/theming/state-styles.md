# State styles

Interactive components expose the full state matrix:

**default · hover · focused · pressed · disabled · selected · loading · error**

- State visuals come from component `ThemeExtension` classes (e.g.
  `FwButtonColors`), resolved per variant × intent × size × state — the
  M3 `ButtonStyle` shape.
- `*StyleDelta` applies caller overrides on top of theme resolution
  without replacing the whole style.
- Disabled is visually distinct from loading: disabled removes
  interactivity; loading shows progress and blocks re-entry.
- Error is distinct from disabled: error keeps the control interactive
  and pairs with an error message (see [error summary](../forms/error-summary.md)).

Focus is always visible: the `FwColorRole.focusRing` token renders a
themeable ring for keyboard focus (`focus-visible` semantics). Never remove
focus indicators to "clean up" a design.
