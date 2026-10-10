# Performance & profiling

- Profile in **release mode** on representative hardware — never debug
  timing.
- Watch: build/layout/frame cost of large lists (virtualize past your
  published collection limits), image memory (`ImageCache` bounds,
  appropriately sized providers), and shader warm-up on first paint.
- `FwSkeleton` shimmer is GPU-cheap and reduced-motion safe; don't
  invent heavier placeholders.
- Publish collection-size limits per data component (`FwDataTable`
  documents its small-data-first contract; virtualization is explicit,
  not automatic).

Record findings in the [friction log](../pilots/friction-log.md).
