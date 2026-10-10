# Scrolling & slivers

- `L08` scroll areas and `L12` sliver adapters bridge framework widgets
  into `CustomScrollView` slivers.
- Pull-to-refresh (`B10`) wraps scrollables with refresh + infinite
  scroll; loading, error, and empty states are part of the contract.

Rules:

- One scrollable per axis per region; nested scrollables need explicit
  extents and a deliberate physics choice.
- Preserve scroll position across theme/width changes (state hoisting,
  `PageStorageKey` where appropriate) — the Phase 5 exit gate tests this.
- Reduced motion: programmatic scrolls jump instead of animating.
